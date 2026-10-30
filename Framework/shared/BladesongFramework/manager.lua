local F,root=...

local J=F._json
local catalogue=assert(loadfile(root..'catalogue.lua'))()

local M={actions={},entries={},page='installed',generation=0}

local function valid(o)return F._valid(o)end

local function obj(path)local o=StaticFindObject(path);assert(valid(o),'Missing '..path);return o end

local function text(s)return obj('/Script/Engine.Default__KismetTextLibrary'):Conv_StringToText(tostring(s or ''))end

local function new(panel,kind)local o=StaticConstructObject(obj('/Script/UMG.'..kind),panel.WidgetTree);assert(valid(o),kind..' unavailable');return o end

local function widget(context,class)return obj('/Script/UMG.Default__WidgetBlueprintLibrary'):Create(context,class,context:GetOwningPlayer())end

local function loadasset(path)

 local o=StaticFindObject(path);if valid(o)then return o end

 local p,a=path:match('^(.*)%.([^%.]+)$');local h=require('UEHelpers')

 return obj('/Script/AssetRegistry.Default__AssetRegistryHelpers'):GetAsset({PackageName=h.FindOrAddFName(p),AssetName=h.FindOrAddFName(a)})

end

local function find(w,name)

 if not valid(w)then return end;if w:GetFName():ToString()==name then return w end

 if w:IsA(obj('/Script/UMG.PanelWidget'))then for i=0,w:GetChildrenCount()-1 do local f=find(w:GetChildAt(i),name);if f then return f end end end

end

local function label(panel,s,size)

 local w=new(panel,'TextBlock');w:SetText(text(s));local font=w.Font;local reference=M.main.VersionText.Font;if valid(M.main.WBP_OptionsMenu)and valid(M.main.WBP_OptionsMenu.ScreenResolutionText)then reference=M.main.WBP_OptionsMenu.ScreenResolutionText.Font end;font.FontObject=reference.FontObject;font.TypefaceFontName=reference.TypefaceFontName;font.Size=size or 24;w:SetFont(font);w:SetAutoWrapText(true);w:SetVisibility(3)

 w:SetColorAndOpacity({SpecifiedColor={R=.56,G=.51,B=.35,A=1},ColorUseRule=0});return w

end

local function add(parent,w)local slot=parent:AddChildToVerticalBox(w);slot:SetHorizontalAlignment(0);slot:SetPadding({Left=12,Right=12,Top=8,Bottom=8});return slot end

local function button(panel,caption,callback)

 local ref=M.main.QuitButton;if panel~=M.main and valid(M.main.WBP_OptionsMenu)and valid(M.main.WBP_OptionsMenu.WBP_BladesongButton)then ref=M.main.WBP_OptionsMenu.WBP_BladesongButton end;local w=widget(panel,ref:GetClass());assert(valid(w));w:SetStyle(ref:GetStyle():GetClass());w:SetCaption(text(caption));w:SetMinDimensions(0,64);w:SetToolTipText(text(''))

 M.actions[w:GetAddress()]={widget=w,callback=callback};if M.rendering_content then M.content_action_ids=M.content_action_ids or {};M.content_action_ids[#M.content_action_ids+1]=w:GetAddress()end;return w

end

function M.Close()

 if valid(M.panel)then
  if valid(M.switcher)then local active=M.switcher:GetActiveWidget();if valid(active)and active:GetAddress()==M.panel:GetAddress()and valid(M.previous_page)then M.switcher:SetActiveWidget(M.previous_page)end end
  M.panel:RemoveFromParent()
 end
 M.switcher=nil;M.previous_page=nil;M.awaiting_page=nil;M.page_requested_at=nil;M.content=nil;M.tabs=nil;M.tabstate=nil;M.rendering_content=false

 M.panel=nil;M.actions={};if valid(M.entry)then M.actions[M.entry:GetAddress()]={widget=M.entry,callback=M.Open}end

end

function M.Render()

 if not valid(M.content)then return end

 for _,id in ipairs(M.content_action_ids or {})do M.actions[id]=nil end;M.content_action_ids={};M.content:ClearChildren();M.rendering_content=true

 local function line(s,target,size)add(target or M.content,label(M.panel,s,size or 26))end

 local function action(c,f,target)
  local holder=new(M.panel,'SizeBox');holder:SetWidthOverride(420);holder:SetContent(button(M.panel,c,f));local slot=add(target or M.content,holder);slot:SetHorizontalAlignment(1);return holder
 end

 if M.page=='installed'then

  local community,utilities=catalogue.partition(F.GetRegisteredMods())
  line('INSTALLED MODS',nil,28)
  line('Manage your mods here. Enable and disable changes take effect after restarting the game.',nil,24)
  local function render_mod(mod)
   local frame=new(M.panel,'Border');frame:SetBrushColor({R=.20,G=.19,B=.13,A=1});frame:SetPadding({Left=2,Top=2,Right=2,Bottom=2});add(M.content,frame)
   local inside=new(M.panel,'Border');inside:SetBrushColor({R=.008,G=.008,B=.006,A=.97});inside:SetPadding({Left=22,Top=18,Right=22,Bottom=18});frame:SetContent(inside)
   local body=new(M.panel,'VerticalBox');inside:SetContent(body)
   local name=mod.name or mod.id
   if mod.id=='PreconstructionLibraryProbe'and name==mod.id then name='Preconstruction Library'end
   local heading=new(M.panel,'HorizontalBox');add(body,heading)
   local title=label(M.panel,name,32);local title_slot=heading:AddChildToHorizontalBox(title);title_slot:SetSize({Value=1,SizeRule=1});title_slot:SetVerticalAlignment(2)
   if mod.version and mod.version~='0.0.0'then local vs=heading:AddChildToHorizontalBox(label(M.panel,'v'..mod.version,24));vs:SetVerticalAlignment(2)end
   if mod.author and mod.author~=''then line('By '..mod.author,body,23)end
   if mod.description and mod.description~=''and not mod.discovered then line(mod.description,body)end
   line((mod.enabled==false and 'Disabled'or 'Enabled')..'  |  '..(mod.integration=='ordinary'and 'Ordinary UE4SS mod'or(mod.integration=='manifest'and 'Manifest integration'or 'SDK integration')),body,24)
   if mod.integration=='ordinary'then line('Uses its own game interfaces; behavior has not been verified by the framework.',body,23)elseif mod.compatibility then line('Compatibility: '..mod.compatibility.state..' (behavior not automatically verified)',body,23)end
   for _,failure in ipairs(mod.failures or {})do line(failure,body,24)end
   for page,definition in pairs(mod.pages or {})do action(definition.title or page,function()M.Close();F.SendPage(mod.id,page)end,body)end
   if mod.id~='BladesongModFramework'then action((mod.enabled==false and 'Enable'or 'Disable')..' on next launch',function()M.Job('toggle',{id=mod.id,enabled=mod.enabled==false})end,body)end
  end
  for _,mod in ipairs(community)do render_mod(mod)end
  if #utilities>0 then
   action((M.show_utilities and 'Hide 'or 'Show ')..'UE4SS utilities ('..#utilities..')',function()M.show_utilities=not M.show_utilities;M.Render()end)
   if M.show_utilities then for _,mod in ipairs(utilities)do render_mod(mod)end end
  end

 elseif M.page=='browse'then
  line('COMMUNITY MODS',nil,28)
  line('The index lists names and repository links. Details belong to each mod author; release metadata is reviewed before installation.',nil,24)
  M.registry=new(M.panel,'EditableTextBox');M.registry:SetHintText(text('HTTPS URL to mod-index.json'));local preferences=F.GetSettings('BladesongModFramework');if preferences.registry_url and preferences.registry_url~=''then M.registry:SetText(text(preferences.registry_url))end;add(M.content,M.registry)
  action('Refresh catalogue',function()local url=obj('/Script/Engine.Default__KismetTextLibrary'):Conv_TextToString(M.registry:GetText());F.SetSetting('BladesongModFramework','registry_url',url);M.Job('browse',{index_url=url})end)
  for _,entry in ipairs(M.browser or {})do
   line(entry.manifest and entry.manifest.name or entry.name,nil,30)
   if entry.manifest then line(entry.manifest.description or '',nil,24);line('Repository version '..entry.manifest.version..(entry.cached and ' (cached)'or ''),nil,23)
    action('Review release',function()M.page='install';M.tabstate.active_tab_id='install';M.Job('inspect',{url=entry.repository})end)
   else line('Repository unavailable: '..(entry.error or ''),nil,23)end
  end
 elseif M.page=='install'then

  line('Paste a public GitHub repository/release URL, release asset, or HTTPS manifest/archive. Review first; installing runs publisher code after restart.')

  M.url=new(M.panel,'EditableTextBox');M.url:SetHintText(text('https://github.com/owner/repository'));add(M.content,M.url)

  action('Inspect URL',function()local t=obj('/Script/Engine.Default__KismetTextLibrary'):Conv_TextToString(M.url:GetText());M.Job('inspect',{url=t})end)

  if M.preview then

   line(M.preview.name..' '..M.preview.version..' by '..(M.preview.author or 'Unknown'));line(M.preview.description or '')

   line('Source: '..M.preview.source..' | Compatibility: '..(M.preview.compatibility or 'unknown'))

   action('Approve download and stage installation',function()M.Job('stage',{source=M.preview.source,expected_id=M.preview.id,expected_version=M.preview.version,expected_manifest_sha256=M.preview.manifest_sha256})end)

  end

 elseif M.page=='updates'then

  line('Updates are checked against each installed manifest repository. Stable/prerelease and pinned versions are respected. Unknown compatibility cannot be auto-installed.')

  action('Check for updates',function()M.Job('updates',{})end)

  for _,update in ipairs(M.updates or {})do

   line(update.name..' '..update.version..' | '..update.compatibility);line(update.release_notes or '')

   action('Review '..update.name,function()M.preview=update;M.page='install';M.Render()end)

  end

  action('Restart & Apply approved changes',function()

   M.restart_review=not M.restart_review

   if M.restart_review then line('Save any unsaved gameplay first. This closes Bladesong normally; staged changes apply only after it exits.');action('Confirm saved — restart and apply',function()M.Job('restart',{});M.quit_after_job=true end)end

  end)

 elseif M.page=='settings'then

  line('Registered settings (saved per mod; changes are read by the owning mod).')

  for _,mod in ipairs(F.GetRegisteredMods())do for key,definition in pairs(mod.settings or {})do

   local settings=F.GetSettings(mod.id);local value=settings[key];if value==nil then value=definition.default end

   if definition.type=='boolean'then action(mod.name..': '..key..' = '..tostring(value),function()F.SetSetting(mod.id,key,not value);M.Render()end)

   else line(mod.name..': '..key..' = '..tostring(value)..' (edit JSON for non-boolean values in this preview)')end

  end end

 else

  line('Framework '..F.VERSION..' | API '..F.API_VERSION);line('Game: '..F.GetGameVersion()..' | Branch: '..F.GetGameBranch()..' | Profile: '..F.GetCompatibilityProfile())

  line('Compatibility is capability-based; Main and Bleeding Edge are not both runtime tested.')

  action('Export diagnostic report',function()F.ExportDiagnostics(root..'../../BladesongModFramework/Data/diagnostics.json');line('Diagnostic report exported without usernames, hardware IDs, or save contents.')end)

  for _,err in ipairs(F.errors)do line(err)end

 end

 if M.message then line(M.message)end
 M.rendering_content=false

end

function M.Job(operation,args)

 if M.busy then return end

 local ok,err=pcall(function()F.StartJob(operation,args,function(result)

  M.busy=false;M.message=result.error or result.message or result.status

  if result.entries then M.browser=result.entries end;if result.mod then M.preview=result.mod end;if result.updates then M.updates=result.updates end

  if M.quit_after_job and result.status=='waiting_for_exit'then

   obj('/Script/Engine.Default__KismetSystemLibrary'):QuitGame(M.main,M.main:GetOwningPlayer(),0,false);return

  end

  M.Render()

 end);M.busy=true;M.message='Working…';M.Render()end)

 if not ok then M.busy=false;M.message=tostring(err);M.Render()end

end

function M.Open()

 M.Close()

 local class=loadasset('/Game/PCL/UI/WBP_PCL_LibraryEntry.WBP_PCL_LibraryEntry_C');assert(valid(class),'Shared PCL menu asset unavailable')

 local panel=widget(M.main,class);M.panel=panel

 local rootbox=find(panel.WidgetTree.RootWidget,'PCL_EntryRoot');assert(valid(rootbox),'Existing PCL root unavailable')

 rootbox:SetWidthOverride(1600);rootbox:SetMaxDesiredWidth(1600);rootbox:SetHeightOverride(1740)


 local frame=new(panel,'Border');frame:SetBrushColor({R=.20,G=.19,B=.13,A=1});frame:SetPadding({Left=2,Top=2,Right=2,Bottom=2});rootbox:SetContent(frame)
 local border=new(panel,'Border');border:SetBrushColor({R=.008,G=.008,B=.006,A=.97});border:SetPadding({Left=28,Top=24,Right=28,Bottom=24});frame:SetContent(border)

 local body=new(panel,'VerticalBox');border:SetContent(body);add(body,label(panel,'BLADESONG MODS',40))

 local nav=new(panel,'CanvasPanel');local navbox=new(panel,'SizeBox');navbox:SetHeightOverride(80);navbox:SetContent(nav);add(body,navbox)

 local env=setmetatable({}, {__index=_G});env.pcl151723_new=new;env.pcl151723_label=function(p,c,size)return label(p,c,size)end;env.pcl15171_to_text=text;env.is_valid=valid

 env.pcl151762_transparent_style=function()return loadasset('/Game/UI/Style/ButtonStyle_Transparent.ButtonStyle_Transparent_C')end

 env.pcl151762_remove_native_chrome=function()end

 env.pcl151762_button=function(_,_,c,_,extra)return button(panel,c,function()M.page=extra.tab_id;M.tabstate.active_tab_id=M.page;M.Render();M.tabs.update(M.tabstate)end)end

 local tabs=assert(loadfile(root..'ui/primitives.lua','t',env))();M.tabs=tabs

 env.PCL_FOLDER_TABS={is_active=function(id,state)return id==state.active_tab_id end}

 local ts={home=panel,folder_tabs={},active_tab_id=M.page};M.tabstate=ts

 for i,definition in ipairs({{'installed','Installed'},{'browse','Browse'},{'install','Install'},{'updates','Updates'},{'settings','Settings'},{'developer','Developer'}})do tabs.tab(ts,nav,definition[2],'manager_tab',(i-1)*240,{id=definition[1],width=240})end;tabs.update(ts)

 local scroll=new(panel,'ScrollBox');local slot=add(body,scroll);slot:SetSize({Value=1,SizeRule=1});M.content=new(panel,'VerticalBox');scroll:AddChild(M.content)

 M.rendering_content=false
 local footer=new(panel,'SizeBox');footer:SetWidthOverride(360);footer:SetContent(button(panel,'Close',M.Close));local footslot=add(body,footer);footslot:SetHorizontalAlignment(1);footslot:SetPadding({Left=12,Right=12,Top=22,Bottom=4})
 M.Render();M.rendering_content=false
 M.switcher=M.main.WidgetSwitcher;assert(valid(M.switcher),'Native main-menu switcher unavailable')
 M.previous_page=M.switcher:GetActiveWidget();local pageslot=M.switcher:AddChild(panel);pageslot:SetHorizontalAlignment(2);pageslot:SetVerticalAlignment(2)
 M.awaiting_page=true;M.page_requested_at=os.time()
 M.switcher:SetActiveWidget(panel)
 print('[BMF] Mods page requested through native menu switcher\n')


end

function M.Monitor()
 if valid(M.panel)and valid(M.switcher)then
  -- CommonAnimatedSwitcher keeps reporting the outgoing page during its animation.
  -- That is not a Back/navigation action and must never remove the incoming page.
  if M.switcher:IsCurrentlySwitching()or M.switcher:IsTransitionPlaying()then return end
  local active=M.switcher:GetActiveWidget()
  if valid(active)and active:GetAddress()==M.panel:GetAddress()then
   if M.awaiting_page then print('[BMF] Mods page active; native transition settled\n')end
   M.awaiting_page=false
   return
  elseif M.awaiting_page then
   if os.time()-(M.page_requested_at or os.time())<5 then return end
   print('[BMF] Mods page activation timed out; returning to previous native page\n')
   if valid(M.previous_page)then M.switcher:SetActiveWidget(M.previous_page)end
   M.Close()
  else M.Close()end
 end

 if not valid(M.main)or not M.main:IsVisible()then

  M.Close();M.main=nil;M.entry=nil

  for _,w in pairs(FindAllOf('WBP_MainMenu_C')or {})do if valid(w)and w:IsVisible()and valid(w.QuitButton)and valid(w.QuitButton:GetParent())then M.main=w;break end end

 end

 if valid(M.main)and (not valid(M.entry)or not valid(M.entry:GetParent()))then

  local old=M.entries[M.main:GetAddress()];if old and valid(old)and valid(old:GetParent())then M.entry=old;M.actions[old:GetAddress()]={widget=old,callback=M.Open};return end

  local options=M.main.OptionsButton
  local parent=options:GetParent()
  assert(valid(parent)and parent:IsA(obj('/Script/UMG.WrapBox')),'Native main-menu WrapBox unavailable')
  local function copy_slot(slot)
   return {padding={Left=slot.Padding.Left,Top=slot.Padding.Top,Right=slot.Padding.Right,Bottom=slot.Padding.Bottom},
    horizontal=slot.HorizontalAlignment,vertical=slot.VerticalAlignment,fill=slot.bFillEmptySpace,
    newline=slot.bForceNewLine,span=slot.FillSpanWhenLessThan}
  end
  local function apply_slot(slot,style)
   slot:SetPadding(style.padding);slot:SetHorizontalAlignment(style.horizontal);slot:SetVerticalAlignment(style.vertical)
   slot:SetFillEmptySpace(style.fill);slot:SetNewLine(style.newline);slot:SetFillSpanWhenLessThan(style.span)
  end
  local insertion=parent:GetChildIndex(options);assert(insertion>=0,'Options not in native menu')
  local style=copy_slot(options.Slot)
  local tail={}
  for i=insertion,parent:GetChildrenCount()-1 do local child=parent:GetChildAt(i);tail[#tail+1]={widget=child,style=copy_slot(child.Slot)}end
  local entry=button(M.main,'MODS',M.Open)
  entry:SetMinDimensions(options.MinWidth,options.MinHeight)
  -- Preserve the actual native widgets, callbacks and each slot's layout settings.
  -- Reappend only the tail because UPanelWidget has no reflected insert-at method.
  for _,item in ipairs(tail)do item.widget:RemoveFromParent()end
  apply_slot(parent:AddChildToWrapBox(entry),style)
  for _,item in ipairs(tail)do apply_slot(parent:AddChildToWrapBox(item.widget),item.style)end
  M.entry=entry
  M.entries[M.main:GetAddress()]=M.entry;print('[BMF] Native main-menu Mods button attached\n')

 end

end

RegisterHook('/Script/CommonUI.CommonButtonBase:HandleButtonClicked',function(context)

 local b=context:get();if not valid(b)then return end;local a=M.actions[b:GetAddress()]

 if a and valid(a.widget)then local ok,e=pcall(a.callback);if not ok then F.errors[#F.errors+1]=tostring(e);print('[BMF] '..tostring(e)..'\n')end end

end)

return M

