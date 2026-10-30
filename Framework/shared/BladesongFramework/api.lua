local root=assert(...,'Framework module root required')
local J=assert(loadfile(root..'json.lua'))();local V=assert(loadfile(root..'semver.lua'))()
local map=assert(loadfile(root..'compat/shared.lua'))()
local patches=assert(loadfile(root..'compat/patches.lua'))(root,J)
local F={VERSION='0.1.6',API_VERSION='1.0.0',MANIFEST_VERSION=1,root=root,callbacks={},errors={}}
local function valid(o)local ok,v=pcall(function()return o and o:IsValid()end);return ok and v end
local function get(k)if not ModRef then return nil end;return ModRef:GetSharedVariable('BMF1:'..k)end
local function set(k,v)assert(ModRef,'UE4SS ModRef unavailable');ModRef:SetSharedVariable('BMF1:'..k,v)end
local function snapshot()local s=get('status');if not s then return {}end;local ok,v=pcall(J.decode,s);return ok and v or {}end
local profile_key,profile
local function refresh_profile()
 local identity=snapshot();local key=tostring(identity.sha256 or '')..':'..tostring(identity.branch or '')
 if profile_key~=key then
  profile_key=key
  local ok,result=pcall(patches.select,identity)
  profile=ok and result or {id='unknown',branch='unknown',status='Compatibility patch rejected: '..tostring(result),overrides={},native_helpers={}}
  if not ok then F.errors[#F.errors+1]=profile.status end
  local defaults=assert(loadfile(root..'compat/shared.lua'))()
  for _,category in ipairs({'objects','classes','functions','events','capabilities','properties'})do
   map[category]=defaults[category]
   for name,value in pairs((profile.overrides or {})[category]or {})do map[category][name]=value end
  end
 end
 return profile
end
F._applyCompatibility=refresh_profile
function F.GetCompatibilityData(mod_id)
 local patch=refresh_profile()
 if mod_id~=nil then
  assert(type(mod_id)=='string'and mod_id:match('^[%w_%-]+$'),'Invalid mod id')
  return J.decode(J.encode((patch.mod_data or {})[mod_id]or {}))
 end
 return J.decode(J.encode({id=patch.id,branch=patch.branch,buildid=patch.buildid,sha256=patch.sha256,status=patch.status,native_helpers=patch.native_helpers or {}}))
end
function F.GetFrameworkVersion()return F.VERSION end
function F.GetAPIVersion()return F.API_VERSION end
function F.GetGameVersion()return snapshot().game or 'unknown'end
function F.GetGameBranch()return snapshot().branch or 'unknown'end
function F.GetCompatibilityProfile()return refresh_profile().id end
function F.IsReady()return snapshot().ready==true end
function F.HasCapability(name)
 local patch=refresh_profile()
 if name=='native.pcl'then return patch.legacy_pcl_native_verified==true end
 local path=map.capabilities[name];if not path then return false end
 local ok,o=pcall(StaticFindObject,path);return ok and valid(o)
end
function F.ResolveObject(name)refresh_profile();local path=map.objects[name];if not path then return nil,'unknown object alias'end;local ok,o=pcall(StaticFindObject,path);if not ok or not valid(o)then return nil,'object unavailable: '..name end;return o end
function F.ResolveClass(name)refresh_profile();local path=map.classes[name];if not path then return nil,'unknown class alias'end;local ok,o=pcall(StaticFindObject,path);if not ok or not valid(o)then return nil,'class unavailable: '..name end;return o end
local function call(object,alias,...)
 refresh_profile()
 if not valid(object)then return nil,'object unavailable'end
 local args={...};local ok,r=pcall(function()return object[map.functions[alias]](object,table.unpack(args))end)
 if not ok then return nil,'unsupported call '..alias..': '..tostring(r)end
 return r
end
local default_game_mode,default_game_state
local services=assert(loadfile(root..'internal/services.lua'))(root,{
 profile=refresh_profile,valid=valid,
 resolve=function(kind,alias)if kind=='class'then return F.ResolveClass(alias)end;return F.ResolveObject(alias)end,
 service=function(name,context)
  if name=='game.mode'then return default_game_mode(context)end
  if name=='game.state'then return default_game_state(context)end
  if name=='forge.current'then local gm,e=F.GetGameMode(context);if not gm then return nil,e end;return call(gm,'forge')end
  if name=='sword.current'then local forge,e=F.GetForge(context);if not forge then return nil,e end;return call(forge,'current_sword')end
  if name=='sword.synchronize'then local forge=context or F.GetForge();if not valid(forge)then return nil,'Forge is not open'end;local _,why=call(forge,'synchronize');if why then return nil,why end;return true end
  if name=='sword.design'then if not valid(context)then return nil,'invalid sword'end;return context[map.properties.weapon_design]end
  return nil,'unknown internal service'
 end
})
F._services=services
default_game_state=function(context)if context==nil then local o=FindFirstOf('BladesongGameState');if valid(o)then return o end end;local u,e=F.ResolveObject('utils');if not u then return nil,e end;return call(u,'game_state',context)end
default_game_mode=function(context)if context==nil then local o=FindFirstOf('BladesongGameMode');if valid(o)then return o end end;local u,e=F.ResolveObject('utils');if not u then return nil,e end;return call(u,'game_mode',context)end
function F.GetGameState(context)return services.invoke('game.state',context)end
function F.GetGameMode(context)return services.invoke('game.mode',context)end
function F.GetForge(context)
 local forge,e=services.invoke('forge.current',context);if valid(forge)then return forge end;return nil,e or 'Forge is not open'
end
function F.GetCurrentSword(context)local sword,why=services.invoke('sword.current',context);if valid(sword)then return sword end;return nil,why or 'Sword is not available'end
function F.GetSwordDesign(sword)
 if not valid(sword)then return nil,'invalid sword'end
 return services.invoke('sword.design',sword)
end
function F.SynchronizeSword(forge)return services.invoke('sword.synchronize',forge)end
function F.GetSwordSnapshot(sword)
 if sword==nil then local why;sword,why=F.GetCurrentSword();if not sword then return nil,why end end
 if not valid(sword)then return nil,'invalid sword'end
 local ok,result=pcall(function()
  refresh_profile();local design=F.GetSwordDesign(sword);if not design then return nil end
  local name=sword[map.properties.piece_name];if type(name)~='string'then local texts=F.ResolveObject('text');name=texts and texts:Conv_TextToString(name)or ''end
  local parts=design[map.properties.applied_parts];local count=0
  if type(parts)=='table'then count=#parts else parts:ForEach(function()count=count+1;assert(count<=6000,'part count limit')end)end
  assert(count>=0 and count<=6000,'part count limit')
  return {schema_version=1,kind='sword',name=name,part_count=count}
 end)
 if not ok or not result then return nil,'sword snapshot unavailable'end
 return result
end
function F.GetSwordComponents(sword)
 if not valid(sword)or not F.HasCapability('forge.parts')then return nil,'live sword part tree unavailable'end
 local forge,e=F.GetForge();if not forge then return nil,e end
 local current=call(forge,'current_sword');if not valid(current)or current:GetAddress()~=sword:GetAddress()then return nil,'sword is not active in this Forge'end
 local root,e=call(forge,'root_part');if not valid(root)then return {},nil end
 local result,seen,queue={},{},{root}
 local function unwrap(v)local ok,x=pcall(function()return v:get()end);return ok and x or v end
 local ok,why=pcall(function()
  local index=1
  while index<=#queue do
   local part=unwrap(queue[index]);index=index+1
   if valid(part)and not seen[part:GetAddress()]then
    assert(#result<6000,'Sword tree limit');seen[part:GetAddress()]=true;result[#result+1]=part
    part.SlotChildParts:ForEach(function(_,value)queue[#queue+1]=unwrap(value)end)
    part.FreeChildParts:ForEach(function(key,_)queue[#queue+1]=unwrap(key)end)
   end
  end
 end)
 if not ok then return nil,'part traversal unavailable: '..tostring(why)end
 return result
end
function F.RegisterMod(metadata)
 assert(type(metadata)=='table'and type(metadata.id)=='string'and metadata.id:match('^[%w_%-]+$')and #metadata.id<=64,'Invalid mod id')
 assert(type(metadata.name)=='string'and type(metadata.version)=='string','Missing mod name/version');V.parse(metadata.version)
 assert(V.matches('1.0.0',metadata.api or '^1.0.0'),'Unsupported historical framework API')
 metadata.integration='sdk';metadata.discovered=nil
 local wire=J.encode(metadata);assert(#wire<=65536,'Registration too large');set('mod:'..metadata.id,wire)
 local ids=J.decode(get('ids')or '[]');local found=false;for _,id in ipairs(ids)do if id==metadata.id then found=true end end
 if not found then assert(#ids<256,'Mod limit');ids[#ids+1]=metadata.id;set('ids',J.encode(ids))end
 F.id=metadata.id;F.metadata=metadata;F.epoch=get('epoch');return true
end
function F.BindMod(id)
 assert(type(id)=='string'and id:match('^[%w_%-]+$')and #id<=64,'Invalid mod id')
 local raw=get('mod:'..id)
 if not raw then
  local base=root..'../../'..id..'/'
  local file=io.open(base..'mod.json','rb')or io.open(base..'bmf-manifest.json','rb')
  if not file then return nil,'mod manifest unavailable'end
  raw=file:read(65537);file:close();assert(#raw<=65536,'Manifest too large')
 end
 local metadata=J.decode(raw);assert(metadata.id==id,'Manifest ID mismatch')
 return F.RegisterMod(metadata)
end
function F.RegisterPage(id,definition,callback)
 assert(F.id,'Register mod first');assert(type(callback)=='function'and type(definition)=='table','Page definition/callback required')
 F.callbacks[id]=callback
 local data=J.decode(get('mod:'..F.id));data.pages=data.pages or {};data.pages[id]=definition;F.metadata=data;set('mod:'..F.id,J.encode(data));return true
end
function F.Poll()
 if not F.id then return end
 if F.epoch~=get('epoch')and F.IsReady()then F.RegisterMod(F.metadata)end
 local raw=get('command:'..F.id);if not raw or raw==F.last_command then return end;F.last_command=raw
 local ok,msg=pcall(J.decode,raw);if not ok then return end
 if msg.epoch~=get('epoch')then return end
 local cb=F.callbacks[msg.page];if cb then local success,err=pcall(cb,msg);if not success then F.errors[#F.errors+1]=tostring(err)end end
end
function F.SendPage(mod,page)
 assert(type(mod)=='string'and type(page)=='string');F.sequence=(F.sequence or 0)+1
 set('command:'..mod,J.encode({page=page,sequence=F.sequence,time=os.time(),epoch=get('epoch')}));return true
end
function F.GetRegisteredMods()
 local out={};for _,id in ipairs(J.decode(get('ids')or '[]'))do
  local raw=get('mod:'..id);local ok,m=pcall(J.decode,raw or '');if ok then
   m.status='registered';m.failures={}
   if m.api and not V.matches('1.0.0',m.api)then m.failures[#m.failures+1]='Unsupported historical API '..m.api end
   for dep,range in pairs(m.dependencies or {})do local d=get('mod:'..dep);local success,value=pcall(J.decode,d or '');if not success or not V.matches(value.version,range)then m.failures[#m.failures+1]='Dependency '..dep..' '..range end end
   for _,cap in ipairs(m.capabilities or {})do if not F.HasCapability(cap)then m.failures[#m.failures+1]='Capability '..cap end end
   if m.raw_integration then local supported=false;for _,hash in ipairs(m.raw_integration.game_builds or {})do if hash==snapshot().sha256 then supported=true end end;if not supported then m.failures[#m.failures+1]='Raw integration needs a verified replacement for this executable'end end
   if #m.failures>0 then m.status='limited' end
   m.compatibility={state=(m.integration=='ordinary'and 'raw-interfaces-unknown'or(m.integration=='invalid-manifest'and 'invalid-manifest'or(#m.failures>0 and 'requires-framework-work'or 'framework-ready'))),behavior_verified=false}
   out[#out+1]=m
  end
 end;table.sort(out,function(a,b)return a.id<b.id end);return out
end
function F.ExportDiagnostics(path)
 assert(type(path)=='string'and path:match('diagnostics[%w_%.%-]*%.json$'),'Use a diagnostics JSON filename')
 local report={framework=F.VERSION,api=F.API_VERSION,game=F.GetGameVersion(),branch=F.GetGameBranch(),profile=F.GetCompatibilityProfile(),mods=F.GetRegisteredMods(),errors=F.errors}
 local out=assert(io.open(path,'wb'));assert(out:write(J.encode(report)));out:close();return true
end

function F.GetSettings(id)
 assert(type(id)=='string'and id:match('^[%w_%-]+$'),'Invalid mod id')
 local all=J.decode(get('settings')or '{}');return all[id]or {}
end
function F.SetSetting(id,key,value)
 local metadata=J.decode(get('mod:'..id)or '{}');local definition=metadata.settings and metadata.settings[key]
 assert(definition,'Unknown registered setting');assert(type(value)==definition.type,'Incorrect setting type')
 local all=J.decode(get('settings')or '{}');all[id]=all[id]or {};all[id][key]=value;local wire=J.encode(all);assert(#wire<=1048576,'Settings size limit');set('settings',wire);return true
end
function F.Ready(callback)
 assert(type(callback)=='function');local generation=get('epoch');local attempts=0
 local function check()
  if F.IsReady()then callback(F);return end
  attempts=attempts+1;if attempts>120 then print('[BMF] Framework did not become ready; dependent features remain disabled.\n');return end
  assert(type(ExecuteInGameThreadWithDelay)=='function','Game-thread scheduler unavailable')
  ExecuteInGameThreadWithDelay(250,check)
 end
 check()
end
function F.GetNativeHelper(name,directory)
 assert(type(name)=='string'and name:match('^[%w_%-]+%.dll$'),'Invalid native helper name')
 local patch=refresh_profile();local helper=(patch.native_helpers or {})[name]
 if helper then
  if helper.verified~=true then return nil,helper.reason or 'Native helper is not verified for '..patch.id end
  if helper.path then return root..helper.path end
 end
 if patch.legacy_pcl_native_verified~=true then return nil,'Native helper is not verified for '..patch.id end
 if type(directory)~='string'then return nil,'Legacy helper directory required'end
 return directory..name
end


function F.Subscribe(event,callback)
 assert(type(callback)=='function','Event callback required');F.hooks=F.hooks or {}
 if F.hooks[event]then return true end
 refresh_profile();local path=map.events[event];if not path then return nil,'unknown event alias'end
 local ok,fn=pcall(StaticFindObject,path);if not ok or not valid(fn)then return nil,'event unavailable'end
 local installed,a,b=pcall(RegisterHook,path,function(context,...)
  local adapted,arguments,count=services.event(event,context,...)
  if not arguments then F.errors[#F.errors+1]=tostring(count);return end
  local success,err=pcall(callback,adapted,table.unpack(arguments,1,count));if not success then F.errors[#F.errors+1]=tostring(err)end
 end)
 if not installed then return nil,tostring(a)end
 F.hooks[event]={path=path,pre=a,post=b};return true
end
function F.SetComponentTransform(component,transform)
 if not F.HasCapability('component.transform')or not valid(component)then return nil,'component transform unavailable'end
 local class=StaticFindObject('/Script/Engine.SceneComponent');if not valid(class)or not component:IsA(class)then return nil,'SceneComponent required'end
 if type(transform)~='table'then return nil,'transform table required'end
 for _,group in ipairs({'Translation','Scale3D'})do
  if type(transform[group])~='table'then return nil,'complete transform required'end
  for _,axis in ipairs({'X','Y','Z'})do local n=transform[group][axis];if type(n)~='number'or n~=n or math.abs(n)>1000000 then return nil,'invalid transform number'end end
 end
 if type(transform.Rotation)~='table'then return nil,'rotation quaternion required'end
 for _,axis in ipairs({'X','Y','Z','W'})do local n=transform.Rotation[axis];if type(n)~='number'or n~=n or math.abs(n)>1 then return nil,'invalid rotation'end end
 local ok,err=pcall(function()component:K2_SetRelativeTransform(transform,false,{},true)end)
 if not ok then return nil,tostring(err)end;return true
end

function F.OpenCreativeLibrary()
 if not F.HasCapability('ui.native_buttons')then return nil,'native menu navigation unavailable'end
 for _,menu in pairs(FindAllOf('WBP_MainMenu_C')or {})do
  if valid(menu)and menu:IsVisible()and valid(menu.CreativeModeButton)then
   local ok,err=pcall(function()menu.CreativeModeButton:HandleButtonClicked()end)
   if not ok then return nil,tostring(err)end;return true
  end
 end
 return nil,'main menu is not available'
end

-- Internal broker access stays serialized; callbacks and transient UObject references never cross states.
F._json=J;F._version=V;F._get=get;F._set=set;F._map=map;F._valid=valid
return F
