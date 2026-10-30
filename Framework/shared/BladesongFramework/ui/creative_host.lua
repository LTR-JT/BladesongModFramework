-- Shared host: a framework-only Creative/Story instance, or a PCL provider instance.
local F,root,environment,options=...
local C={};options=options or {}
local E=environment or setmetatable({},{__index=_G})
E.BMF_CREATIVE_FRAMEWORK=F;
if options.provider then
 local client=assert(loadfile(root..'worker_client.lua'))(root,F)
 E.BMF_CREATIVE_FRAMEWORK=setmetatable({StartJob=function(operation,args,callback)
  local id=client.StartJob(operation,args,callback)
  local function poll()client.Poll();if next(client.jobs)then E.pcl15179_schedule(100,poll)end end
  E.pcl15179_schedule(100,poll);return id
 end},{__index=F})
end
E.BMF_CREATIVE_ROOT=root;E.BMF_CREATIVE_HAS_PROVIDER=options.provider==true
for key,value in pairs(options)do if key~='provider'then E[key]=value end end
local function valid(object)return F._valid(object)end
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
 E.pcl15171_create_widget=function(context,class)return E.pcl15171_widget_library():Create(context,class,context:GetOwningPlayer())end
 E.pcl15174_load_object=function(path)
  local object=StaticFindObject(path);if valid(object)then return object end
  local package,name=path:match('^(.*)%.([^%.]+)$');local helpers=require('UEHelpers')
  return StaticFindObject('/Script/AssetRegistry.Default__AssetRegistryHelpers'):GetAsset({PackageName=helpers.FindOrAddFName(package),AssetName=helpers.FindOrAddFName(name)})
 end
 E.pcl15171_load_widget_assets=function()
  E.PCL15171_ENTRY_CLASS_OBJ=E.pcl15174_load_object('/Game/PCL/UI/WBP_PCL_LibraryEntry.WBP_PCL_LibraryEntry_C')
  return valid(E.PCL15171_ENTRY_CLASS_OBJ)
 end
 E.pcl15171_widget_by_name=function(owner,name)
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
