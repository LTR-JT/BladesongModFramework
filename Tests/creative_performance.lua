local root=os.getenv('BMF_TEST_ROOT')
local host=assert(loadfile(root..'/Framework/shared/BladesongFramework/ui/creative_host.lua'))
function RegisterHook()end
local F={_valid=function(o)return type(o)=='table'and o.valid~=false end,IsReady=function()return true end,GetRegisteredMods=function()return {}end}
local E=host(F,root..'/Framework/shared/BladesongFramework/').environment
local actual_patch=E.pcl151762_patch_cards
local serial,created,patches,loads,callbacks=0,0,0,0,{}
local function object()
 serial=serial+1;local o={id=serial,valid=true}
 function o:GetAddress()return self.id end
 function o:AddObject(piece)self.pieces=self.pieces or {};self.pieces[#self.pieces+1]=piece end
 return o
end
local home=object();local original=object();local control=object();home.PieceItemsCollection=control
function control:Bind(collection)assert(state.patching,'Binding re-entered card patching');self.bound=collection end
state={home=home,view='all',panel=home,heading={SetText=function()end},buttons={},row_buttons={}}
E.PCL151762_HOME=state;E.pcl151762_context=function()return {},original end
E.pcl151762_restore_cards=function()end;E.pcl151762_patch_cards=function()patches=patches+1 end;E.pcl151762_controls=function()end
E.pcl151731_fresh=function()end;E.pcl15171_to_text=function(v)return v end;E.pcl151762_refresh_native_images=function()end
E.pcl15179_schedule=function(_,callback)callbacks[#callbacks+1]=callback end
E.StaticFindObject=function()return object()end
E.StaticConstructObject=function()created=created+1;return object()end
E.pcl151762_visible=function()return true end
local version=1
E.pcl151762_display_entries=function()return {{code='one',mode='parts',name='One '..version},{code='two',mode='blades',name='Two'}}end
-- Never decode a thumbnail synchronously while opening a tab.
E.pcl151727_load_preview=function()loads=loads+1;return false end;E.pcl151726_has_cache=function()return false end
E.pcl151762_render(state);assert(created==3 and patches==1 and loads==0)
local first=state.library_collection
E.pcl151762_render(state);assert(created==3 and state.library_collection==first and loads==0,'Warm view rebuilt models or decoded previews')
version=2;E.pcl151762_render(state);assert(created==6 and state.library_collection~=first,'Rename did not invalidate model cache')
state.library_collection.valid=false;E.pcl151762_render(state);assert(created==9,'Dead collection was reused')
-- Queue cancellation must not touch objects belonging to a closed screen.
E.PCL151762_HOME=nil
for _,callback in ipairs(callbacks)do callback()end
assert(loads==0)
print('PASS: warm tab reuses collection; rename and invalid objects rebuild; previews never decode in click path; closed-screen work cancels')

local restores=0
E.pcl151762_restore_cards=function()restores=restores+1;state.native_cards={} end
control.ItemPanel={GetChildrenCount=function()return 0 end};control.InstantiatedViewModels={ForEach=function()end}
state.open=true;state.patching=false;state.card_patch_key=nil
actual_patch(state);actual_patch(state);assert(restores==1,'Duplicate binding events rebuilt unchanged controls')
state.library_selecting=true;actual_patch(state);assert(restores==2,'Selection mode failed to invalidate controls')
-- Index/name parsing preserves order and invalidates the scalar cache on edits.
local old_open=io.open;local files={['parts/library.index']='PCL_LIBRARY_INDEX_V1\none\none\n# comment\ntwo\n',['parts/names.index']='one\tCustom%20name\tOriginal\n'}
io.open=function(path)if files[path]then return {read=function()return files[path]end,close=function()end}end end
local C=assert(loadfile(root..'/Framework/shared/BladesongFramework/ui/library_cache.lua'))()
local first=C.entries('parts','parts/','parts/library.index');assert(#first==2 and first[1].name=='Custom name')
assert(C.entries('parts','parts/','parts/library.index')==first)
files['parts/names.index']='one\tRenamed\tOriginal\n'
local renamed=C.entries('parts','parts/','parts/library.index');assert(renamed~=first and renamed[1].name=='Renamed')
files['parts/library.index']='two\n';assert(#C.entries('parts','parts/','parts/library.index')==1)
io.open=old_open
print('PASS: repeated bind hooks are idempotent; selection, rename and delete invalidate the relevant caches')

-- A full-card hit target leaves the native content in place and restores it
-- when multi-delete exits. Cover both direct overlay and content wrappers.
local function panel(kind)
 local widget=object();widget.kind=kind;widget.children={}
 function widget:AddChildToOverlay(child)
  assert(not child.parent);self.children[#self.children+1]=child;child.parent=self
  return {SetHorizontalAlignment=function(_,alignment)assert(alignment==0)end,
          SetVerticalAlignment=function(_,alignment)assert(alignment==0)end}
 end
 function widget:SetContent(child)
  assert(not self.children[1] and not child.parent)
  self.children[1]=child;child.parent=self
 end
 function widget:GetContent()return self.children[1]end
 function widget:GetParent()return self.parent end
 function widget:RemoveFromParent()
  local parent=self.parent
  if not parent then return end
  for i,child in ipairs(parent.children)do if child==self then table.remove(parent.children,i);break end end
  self.parent=nil
 end
 return widget
end
E.pcl151762_class=function(widget,kind)return widget and widget.kind==kind end
E.pcl151723_new=function(_,kind)return panel(kind)end
for _,kind in ipairs({'Overlay','ContentWidget'})do
 local card,content,hit=panel(kind),panel('visuals'),panel('hit')
 if kind=='Overlay'then card:AddChildToOverlay(content)else card:SetContent(content)end
 local record={view={WidgetTree={RootWidget=card}},selection_hit=hit}
 E.pcl151762_mount_selection_hit(record,hit)
 local overlay=kind=='Overlay'and card or card:GetContent()
 assert(overlay.children[1]==content and overlay.children[2]==hit)
 E.pcl151762_remove_selection_hit(record)
 assert(card.children[1]==content and #card.children==1 and not hit.parent)
end
print('PASS: full-card selection target layers above and restores the native card')

-- Main menu travels directly; a pause-menu click or delayed widget must not be required.
local player=object();home.GetOwningPlayer=function()return player end
local travelled,cleaned=0,0
E.PCL151762_HOME=state;state.busy=false;state.confirm=nil;E.PCL151762_IMPORT=nil
E.pcl151762_cleanup_home=function()cleaned=cleaned+1;E.PCL151762_HOME=nil end
E.FindAllOf=function()error('Main menu navigation must not open or search the pause menu')end
E.require=function(name)assert(name=='UEHelpers');return {FindOrAddFName=function(value)assert(value=='MainMenu');return value end}end
E.gameplay_statics_15=function()return {OpenLevel=function(_,context,level,absolute,options)
 assert(context==player and level=='MainMenu'and absolute==true and options=='');assert(cleaned==1);travelled=travelled+1
end}end
E.pcl151762_exit_to_main(state);assert(travelled==1 and cleaned==1)
state.busy=true;assert(not pcall(E.pcl151762_exit_to_main,state));assert(travelled==1 and cleaned==1)
print('PASS: Creative Main menu cleans up its UI and travels directly, without opening the escape menu; busy operations block travel')
