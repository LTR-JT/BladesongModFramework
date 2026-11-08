-- Shared host: a framework-only Creative/Story instance, or a PCL provider instance.
local F,root,environment,options=...
local C={};options=options or {}
local E=environment or setmetatable({},{__index=_G})
E.BMF_CREATIVE_FRAMEWORK=F;
if options.provider then
 local client=assert(loadfile(root..'worker_client.lua'))(root,F)
 E.BMF_CREATIVE_FRAMEWORK=setmetatable({StartJob=client.StartJob},{__index=F})
end
E.BMF_CREATIVE_ROOT=root;E.BMF_CREATIVE_HAS_PROVIDER=options.provider==true
for key,value in pairs(options)do if key~='provider'then E[key]=value end end
local function valid(object)return F._valid(object)end
E.bmf_creative_download_bridge=function()
 local path,why=F.GetNativeHelper('pcl_download_capture_151762.dll')
 if not path then return nil,why end
 local bridge={}
 for _,name in ipairs({'probe','arm_home','status','cancel','failed'})do
  local fn,err=package.loadlib(path,'pcl_download_'..name)
  if not fn then return nil,err end
  bridge[name]=fn
 end
 if bridge.probe()~=1 then return nil,'Download adapter does not match the game executable' end
 return bridge
end
E.bmf_creative_share_bridge=function()
 local path,why=F.GetNativeHelper('pcl_download_capture_151762.dll')
 if not path then return nil,why end
 local bridge={}
 for _,name in ipairs({'send','status','byte'})do
  local fn=package.loadlib(path,'bmf_creative_share_'..name)
  if not fn then return nil,'Sharing from Creative is unavailable on this game build' end
  bridge[name]=fn
 end
 local cache,err=F.GetNativeHelper('pcl_local_cache_151733.dll')
 if not cache then return nil,err end
 local copy,copy_error=package.loadlib(cache,'pcl_cache_copy_word')
 if not copy then return nil,copy_error end
 bridge.copy=copy
 return bridge
end
E.bmf_creative_archive_services=function()
 local path,why=F.GetNativeHelper('pcl_local_cache_151733.dll')
 assert(path,why)
 local store=assert(package.loadlib(path,'bmf_creative_archive_store'),'Creative sword archive helper is unavailable')
 local restore=assert(package.loadlib(path,'bmf_creative_archive_restore'),'Creative sword restore helper is unavailable')
 local saveclass=StaticFindObject('/Script/Bladesong.CreativeModeSave')
 local piececlass=StaticFindObject('/Script/Bladesong.Piece')
 local statics=E.gameplay_statics_15()
 assert(valid(saveclass) and valid(piececlass) and valid(statics),'Creative save services are unavailable')
 return {
  bridge={store=store,restore=restore},statics=statics,saveclass=saveclass,piececlass=piececlass,valid=valid,
  text=E.pcl151762_text,to_text=E.pcl15171_to_text,
  construct=function(class,owner)local piece=StaticConstructObject(class,owner);E.pcl151731_fresh(piece);return piece end,
 }
end
if not options.provider then
 E.is_valid=valid
 E.log=function(message)print('[BMF Creative] '..tostring(message)..'\n')end
 E.safe_full_name=function(object)local ok,value=pcall(function()return object:GetFullName()end);return ok and value or tostring(object)end
 E.pcl15179_schedule=function(delay,callback)return ExecuteInGameThreadWithDelay(delay,function()local ok,why=pcall(callback);if not ok then E.log(why)end end)end
 E.pcl151114_unwrap=function(value)local ok,result=pcall(function()return value:get()end);return ok and result or value end
 E.pcl15171_unwrap=E.pcl151114_unwrap
 E.pcl15171_trim=function(value)return value:match('^%s*(.-)%s*$')end
 E.pcl15171_to_text=function(value)return StaticFindObject('/Script/Engine.Default__KismetTextLibrary'):Conv_StringToText(value)end
 E.pcl15171_from_text=function(value)
  if type(value)=='string'then return value end
  local ok,text=pcall(function()return value:ToString()end)
  if ok and type(text)=='string'then return text end
  local converted=StaticFindObject('/Script/Engine.Default__KismetTextLibrary'):Conv_TextToString(value)
  return type(converted)=='string'and converted or converted:ToString()
 end
 E.pcl151731_fresh=function()end
 E.PCL151723_UI={};E.PCL151723_NATIVE_BUTTONS={};E.PCL15171_ACTIONS={};E.PCL15171_BOUND={};E.PCL15171_LAST_CLICK={}
 E.PCL151761_MODE='parts';E.PCL151724_PREVIEWS={}
 E.PCL151761_PARTS_DIR=root..'../../BladesongModFramework/Data/CreativeBackups/'
 E.pcl151112_script_dir=function()return root..'../../BladesongModFramework/Scripts/'end
 E.pcl15171_widget_library=function()return StaticFindObject('/Script/UMG.Default__WidgetBlueprintLibrary')end
 local entry_roots={}
 E.pcl15171_create_widget=function(context,class)
  local widget=E.pcl15171_widget_library():Create(context,class,context:GetOwningPlayer())
  if valid(widget)and valid(E.PCL15171_ENTRY_CLASS_OBJ)and class:GetAddress()==E.PCL15171_ENTRY_CLASS_OBJ:GetAddress()then
   local root=StaticConstructObject(StaticFindObject('/Script/UMG.SizeBox'),widget.WidgetTree)
   widget.WidgetTree.RootWidget=root;root:SetVisibility(4);widget:SetVisibility(4);widget:SetIsEnabled(true)
   entry_roots[widget:GetAddress()]=root
  end
  return widget
 end
 E.pcl15174_load_object=function(path)
  local object=StaticFindObject(path);if valid(object)then return object end
  local package,name=path:match('^(.*)%.([^%.]+)$');local helpers=require('UEHelpers')
  return StaticFindObject('/Script/AssetRegistry.Default__AssetRegistryHelpers'):GetAsset({PackageName=helpers.FindOrAddFName(package),AssetName=helpers.FindOrAddFName(name)})
 end
 E.pcl15171_load_widget_assets=function()
  for _,menu in pairs(FindAllOf('WBP_MainMenu_C')or {})do
   if valid(menu.WBP_OptionsMenu)and valid(menu.WBP_OptionsMenu.ScreenModeApplyFrame)then
    E.PCL15171_ENTRY_CLASS_OBJ=menu.WBP_OptionsMenu.ScreenModeApplyFrame:GetClass();return valid(E.PCL15171_ENTRY_CLASS_OBJ)
   end
  end
  return false
 end
 E.pcl15171_widget_by_name=function(owner,name)
  if valid(owner)and name=='PCL_EntryRoot'and entry_roots[owner:GetAddress()]then return entry_roots[owner:GetAddress()]end
  local seen={}
  local function visit(widget)
   if not valid(widget)or seen[widget:GetAddress()]then return end;seen[widget:GetAddress()]=true
   if widget:GetFName():ToString()==name then return widget end
   if widget:IsA(StaticFindObject('/Script/UMG.PanelWidget'))then
    for i=0,widget:GetChildrenCount()-1 do local found=visit(widget:GetChildAt(i));if found then return found end end
   end
  end
  return valid(owner)and visit(owner.WidgetTree.RootWidget)or nil
 end
 E.pcl151723_new=function(panel,name)return StaticConstructObject(StaticFindObject('/Script/UMG.'..name),panel.WidgetTree)end
 E.pcl151723_label=function(panel,caption,size,secondary)
  local label=E.pcl151723_new(panel,'TextBlock');label:SetText(E.pcl15171_to_text(caption))
  local native=E.PCL151723_UI[panel:GetAddress()].reference.AbilityHistoryPlaceholderText.Font
  local font=label.Font;font.FontObject=native.FontObject;font.TypefaceFontName=native.TypefaceFontName;font.Size=size
  label:SetFont(font);label:SetAutoWrapText(true);label:SetColorAndOpacity({SpecifiedColor={R=.56,G=.51,B=.35,A=1},ColorUseRule=0});return label
 end
 E.pcl151723_button=function(panel,caption,height)
  local reference=E.PCL151723_UI[panel:GetAddress()].reference.LeaveForgeModeButton
  local button=E.pcl15171_create_widget(panel,reference:GetClass());button:SetStyle(reference:GetStyle():GetClass())
  button:SetCaption(E.pcl15171_to_text(caption));button:SetMinDimensions(0,height or 56);button:SetToolTipText(E.pcl15171_to_text(''))
  E.PCL151723_NATIVE_BUTTONS[button:GetAddress()]=true;return button
 end
 E.pcl151723_vadd=function(parent,widget,top,bottom)local slot=parent:AddChildToVerticalBox(widget);slot:SetPadding({Left=0,Top=top or 0,Right=0,Bottom=bottom or 0});slot:SetHorizontalAlignment(0);return slot end
 E.pcl151723_hadd=function(parent,widget,fill,right)local slot=parent:AddChildToHorizontalBox(widget);slot:SetPadding({Left=0,Top=0,Right=right or 0,Bottom=0});slot:SetVerticalAlignment(2);if fill then slot:SetSize({Value=1,SizeRule=1})end;return slot end
 E.pcl15171_bind_button=function(button,action)E.PCL15171_ACTIONS[button:GetAddress()]=action end
 local bridge
 E.pcl151761_bridge=function()
  if bridge then return bridge end
  local path,why=F.GetNativeHelper('pcl_blade_library_151761.dll',root..'native/25431485/')
  assert(path,why);bridge={mkdir=assert(package.loadlib(path,'pcl_blade_mkdir'))};return bridge
 end
 E.gameplay_statics_15=function()return StaticFindObject('/Script/Engine.Default__GameplayStatics')end
end
assert(loadfile(root..'ui/creative_core.lua','t',E))()
E.PCL151759_SCRIPT_READY=true
if not options.provider then
 RegisterHook('/Script/CommonUI.CommonButtonBase:HandleButtonClicked',function(context)
  local button=E.pcl151114_unwrap(context);if not valid(button)then return end
  local action=E.PCL15171_ACTIONS[button:GetAddress()]
  if action then
   ExecuteInGameThreadWithDelay(1,function()
    if valid(button)and E.PCL15171_ACTIONS[button:GetAddress()]==action then E.pcl151762_dispatch(action)end
   end)
  end
 end,function()end)
end
function C.Tick()
 if options.provider or not F.IsReady()then return end
 for _,mod in ipairs(F.GetRegisteredMods())do
  if mod.id=='PreconstructionLibraryProbe'and mod.enabled~=false then
   if E.PCL151762_HOME then E.pcl151762_cleanup_home()end
   return
  end
 end
 local ok,why=pcall(E.pcl151762_monitor_home)
 if not ok and why~=C.last_error then C.last_error=why;E.log(why)end
end
C.environment=E
return C
