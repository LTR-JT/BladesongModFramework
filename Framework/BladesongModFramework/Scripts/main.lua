-- Bladesong Mod Framework 0.1.3. All UObject access stays on the game thread.
if BMF_RUNTIME_STARTED then return end
BMF_RUNTIME_STARTED=true
BMF_ROOT=debug.getinfo(1,'S').source:gsub('^@',''):match('^(.*[\\/])')..'../../shared/BladesongFramework/'
BMF=assert(loadfile(BMF_ROOT..'api.lua'))(BMF_ROOT)
BMF_DATA=BMF_ROOT..'../../BladesongModFramework/Data/'
BMF_JOBS={};BMF_JOB_SEQUENCE=0;BMF_GENERATION=tostring(os.time())..':'..tostring(os.clock())
do local f=io.open(BMF_DATA..'settings.json','rb');if f then local raw=f:read('*a');f:close();local ok=pcall(BMF._json.decode,raw);if ok then BMF._set('settings',raw)end end end
BMF._set('epoch',BMF_GENERATION);BMF._set('ids','[]');BMF._set('status',BMF._json.encode({ready=false,game='identifying',branch='unknown',profile='unknown'}))
BMF.RegisterMod{id='BladesongModFramework',name='Bladesong Mod Framework',author='Bladesong community',description='Shared compatibility layer and in-game mod manager',version=BMF.VERSION,api='^1.0.0',settings={auto_check={type='boolean',default=true},developer_mode={type='boolean',default=false},registry_url={type='string',default='https://raw.githubusercontent.com/LTR-JT/BladesongModFramework/main/mod-index.json'}}}
function BMF.StartJob(operation,args,callback)
 assert(type(ExecuteAsync)=='function','UE4SS asynchronous worker unavailable')
 BMF_JOB_SEQUENCE=BMF_JOB_SEQUENCE+1
 local id='job_'..os.time()..'_'..math.floor(os.clock()*1000)..'_'..BMF_JOB_SEQUENCE
 local job=BMF_ROOT..'../../BladesongModFramework/'..id..'.json'
 local capabilities={};for name in pairs(BMF._map.capabilities)do if BMF.HasCapability(name)then capabilities[#capabilities+1]=name end end
 local f=assert(io.open(job,'wb'));assert(f:write(BMF._json.encode({id=id,operation=operation,args=args or {},capabilities=capabilities})));f:close()
 local service=BMF_ROOT..'../../BladesongModFramework/Scripts/bmf-worker.exe'
 local function quoted(path)assert(not path:find('["&|<>%%!\r\n]'),'Unsafe worker path');return '"'..path..'"'end
 local command='"'..quoted(service)..' '..quoted(job)..'"'
 BMF_JOBS[id]={path=job,callback=callback,started=os.time()}
 ExecuteAsync(function()os.execute(command)end)
 return id
end
function BMF_PollJobs()
 for id,job in pairs(BMF_JOBS)do
  local f=io.open(job.path..'.result.json','rb')
  if f then
   local wire=f:read('*a');f:close();local ok,result=pcall(BMF._json.decode,wire)
   BMF_JOBS[id]=nil;if job.callback then local success,err=pcall(job.callback,ok and result or {status='failed',error='Invalid worker result'});if not success then BMF.errors[#BMF.errors+1]=tostring(err)end end
  elseif os.time()-job.started>180 then BMF_JOBS[id]=nil;if job.callback then job.callback({status='failed',error='Worker timed out. Check framework diagnostics; staged files have not been applied.'})end end
 end
end
BMF_MANAGER=assert(loadfile(BMF_ROOT..'manager.lua'))(BMF,BMF_ROOT)
BMF.StartJob('discover',{},function(result)
 for _,metadata in ipairs(result.mods or {})do
  local id=metadata.id
  if id and id:match('^[%w_%-]+$')and not BMF._get('mod:'..id)then
   BMF._set('mod:'..id,BMF._json.encode(metadata));local ids=BMF._json.decode(BMF._get('ids')or '[]');ids[#ids+1]=id;BMF._set('ids',BMF._json.encode(ids))
  end
 end
end)
BMF.StartJob('identify',{},function(result)
 if result.identity then
  local status=result.identity;status.ready=true;status.profile=nil
  BMF._set('status',BMF._json.encode(status));local patch=BMF._applyCompatibility();status.profile=patch.id;BMF._set('status',BMF._json.encode(status));print('[BMF] Compatibility patch '..patch.id..' branch='..status.branch..' status='..patch.status..'\n')
 else BMF.errors[#BMF.errors+1]=result.error or 'Build identification failed';BMF._set('status',BMF._json.encode({ready=true,game='unknown',branch='unknown',profile='unknown'}))end
end)
function BMF_RuntimeTick()
 if BMF._get('epoch')~=BMF_GENERATION then return end
 local ok,err=pcall(function()
  BMF_PollJobs();BMF.Poll();BMF_MANAGER.Monitor()
  local preferences=BMF.GetSettings('BladesongModFramework')
  if preferences.auto_check~=false and (not BMF_LAST_UPDATE_CHECK or os.time()-BMF_LAST_UPDATE_CHECK>=3600)then
   BMF_LAST_UPDATE_CHECK=os.time();BMF.StartJob('updates',{},function(result)BMF_MANAGER.updates=result.updates or {};if result.status=='failed'then BMF.errors[#BMF.errors+1]=result.error end end)
  end
  local settings=BMF._get('settings')or '{}'
  if settings~=BMF_SAVED_SETTINGS then
   BMF_SAVED_SETTINGS=settings;BMF.StartJob('settings',{settings=BMF._json.decode(settings)},function(result)if result.status=='failed'then BMF.errors[#BMF.errors+1]=result.error end end)
  end
  if BMF_MANAGER.tabs and BMF_MANAGER.tabstate then BMF_MANAGER.tabs.update(BMF_MANAGER.tabstate)end
 end)
 if not ok and tostring(err)~=BMF_LAST_ERROR then BMF_LAST_ERROR=tostring(err);BMF.errors[#BMF.errors+1]=BMF_LAST_ERROR;print('[BMF] '..BMF_LAST_ERROR..'\n')end
 ExecuteInGameThreadWithDelay(500,BMF_RuntimeTick)
end
ExecuteInGameThreadWithDelay(500,BMF_RuntimeTick)
print('[BMF] Framework 0.1.3 initialized; API 1.0.0; branch identity is unknown until verified.\n')
