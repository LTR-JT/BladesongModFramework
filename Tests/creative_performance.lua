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
local canvas,corner=panel('CanvasPanel'),object()
function canvas:AddChildToCanvas(widget)
 assert(widget==corner)
 return {
  SetAnchors=function(_,anchors)assert(anchors.Minimum.X==1 and anchors.Minimum.Y==0 and anchors.Maximum.X==1 and anchors.Maximum.Y==0)end,
  SetAlignment=function(_,align)assert(align.X==1 and align.Y==0)end,
  SetOffsets=function(_,offsets)assert(offsets.Left==-10 and offsets.Top==10 and offsets.Right==72 and offsets.Bottom==72)end,
  SetZOrder=function(_,z)assert(z==1000)end,
 }
end
E.pcl151762_mount_selection_hit({view={WidgetTree={RootWidget=canvas}}},corner,72)
print('PASS: full-card selection target layers above and restores the native card')

local piece=object();piece.WeaponDesignDefinition={AppliedSwordParts={1,2},BladeSwordParts={1}}
local card=object();card.NameText={text='Sword'}
local label=object()
function label:SetText(text)self.text=text end
function label:SetVisibility(value)self.visibility=value end
E.pcl151762_mount_part_label=function(_,title)
 assert(title==card.NameText)
 return {label=label}
end
local counts={open=false}
E.pcl151762_card_part_count(counts,card,piece)
E.pcl151762_card_part_count(counts,card,piece)
assert(card.NameText.text=='Sword' and label.text=='2 parts' and label.visibility==3)
counts.open=true;counts.view='all';counts.piece_entries={[piece:GetAddress()]={mode='parts',code='saved'}}
counts.part_counts={parts={}}
E.pcl151762_card_part_count(counts,card,piece)
assert(label.visibility==1,'An uncached library entry borrowed the stock part count')
counts.part_counts.parts.saved=1
E.pcl151762_card_part_count(counts,card,piece)
assert(label.text=='1 part' and label.visibility==3)
card.NameText.text='Renamed'
counts.part_counts.parts.saved=0
E.pcl151762_card_part_count(counts,card,piece)
assert(card.NameText.text=='Renamed' and label.text=='0 parts')
print('PASS: card captions use attached part counts, preserve renames and omit unknown counts')

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

-- Conjure only registers a fully downloaded piece in the original Creative
-- inventory. Sharing copies the server's code for the card's own piece.
local queued,hidden,added={},0,{}
local game_state,game_mode,inventory=object(),object(),object()
local home=object()
local form={SetVisibility=function()end}
local input={text='Alpha-Bravo-Charlie',GetText=function(self)return self.text end,SetText=function(self,text)self.text=text end}
local piece_class,entry_class=object(),object()
local piece=object()
local service,holder=object(),object()
holder.IsA=function(_,class)return class==entry_class end
holder.GetClass=function()return entry_class end
for _,widget in ipairs({service,holder})do
 widget.SetVisibility=function()end
 widget.RemoveFromParent=function(self)if self.mounted then hidden=hidden-1;self.mounted=false end end
end
home.GetClass=function()return home end
home.PieceItemsCollection={ItemTemplate=entry_class}
local status,saved,fail_save=0,0,false
local bridge={
 status=function()return status end,
 arm_home=function(widget,gm,target,class,pc)
  assert(widget==service.id and gm==game_mode.id and target==holder.id and class==entry_class.id and pc==piece_class.id)
  status=1;return 1
 end,
 cancel=function()status=-9 end,
}
function service:DownloadPiece(code)assert(code=='alpha-bravo-charlie')end
function inventory:AddObject(value)assert(value==piece);added[#added+1]=value end
function inventory:RemoveObject(value)assert(value==piece and added[#added]==value);table.remove(added)end
function game_state:SaveGame()if fail_save then error('save failed')end;saved=saved+1 end
local home_state={home=home,form=form,input=input,download_bridge=bridge,hidden={AddChild=function(_,widget)hidden=hidden+1;widget.mounted=true end}}
E.PCL151762_HOME=home_state
E.pcl151762_context=function()return game_state,inventory,game_mode end
E.pcl151762_status=function(_,message)home_state.notice=message end
E.pcl151762_controls=function()end
E.pcl15179_schedule=function(_,callback)queued[#queued+1]=callback end
E.pcl15171_create_widget=function(_,class)return class==entry_class and holder or service end
E.StaticFindObject=function(path)return path:match('UWPieceInventoryEntry$')and entry_class or piece_class end
E.pcl151726_has_cache=function()error('Conjure must keep the complete sword rather than use a prefab cache')end
E.pcl151762_start_import(home_state,input.text,true)
assert(hidden==2 and #added==0 and saved==0)
table.remove(queued,1)()
assert(#queued==1 and #added==0)
holder.BoundPiece=piece;status=2;table.remove(queued,1)()
assert(hidden==0 and #added==1 and saved==1 and input.text=='' and E.PCL151762_IMPORT==nil)
fail_save=true;status=0
E.pcl151762_start_import(home_state,'alpha-bravo-charlie',true)
status=2;table.remove(queued,1)()
assert(hidden==0 and #added==1 and saved==1 and E.PCL151762_IMPORT==nil)
fail_save=false;status=0
local opened=0
function game_mode:EnterForgeMode(value)
 assert(value==piece and added[#added]==piece and saved==2 and E.PCL151762_IMPORT==nil)
 opened=opened+1
end
E.BMF_CREATIVE_AUTO_LOAD=true
E.pcl151762_start_import(home_state,'alpha-bravo-charlie',true)
E.BMF_CREATIVE_AUTO_LOAD=false
status=2;table.remove(queued,1)()
assert(opened==1 and saved==2 and hidden==0)

local view,host=object(),object()
view.BoundPiece=piece
game_mode.ForgeModeClass=object()
E.gameplay_statics_15=function()
 return {BeginDeferredActorSpawnFromClass=function(_,world,class)
  assert(world==home and class==game_mode.ForgeModeClass);return host
 end}
end
function host:K2_DestroyActor()self.valid=false end
local code,copied='alpha-bravo-charlie',nil
home_state.share_bridge={
 send=function(widget,actor,sword)
  assert(widget==service.id and actor==host.id and sword==piece.id and service.ForgeMode==host and host.Piece==piece)
  status=1;return 1
 end,
 status=function(widget)assert(widget==service.id);return status end,
 byte=function(widget,index)assert(widget==service.id);return code:byte(index+1)end,
 copy=function(size,...)assert(size==#code);copied=string.char(...);return 1 end,
}
E.bmf_creative_share(home_state,{piece=piece,view=view})
assert(not host.valid and hidden==1 and home_state.share_request and not copied)
table.remove(queued,1)()
assert(#queued==1 and not copied)
status=#code+1;table.remove(queued,1)()
assert(copied==code and hidden==0 and not home_state.share_request and saved==2)
assert(not pcall(E.bmf_creative_share,home_state,{piece=object(),view=view}))
print('PASS: Conjure saves the complete sword directly, rolls back on save errors, and Magic Words shares only the selected card')
