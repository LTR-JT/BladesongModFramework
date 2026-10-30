-- Bladesong Mod Framework 0.1.7. All UObject access stays on the game thread.
if BMF_RUNTIME_STARTED then return end
BMF_RUNTIME_STARTED=true
BMF_ROOT=debug.getinfo(1,'S').source:gsub('^@',''):match('^(.*[\\/])')..'../../shared/BladesongFramework/'
BMF=assert(loadfile(BMF_ROOT..'api.lua'))(BMF_ROOT)
BMF_DATA=BMF_ROOT..'../../BladesongModFramework/Data/'
BMF_JOBS={};BMF_JOB_SEQUENCE=0;BMF_GENERATION=tostring(os.time())..':'..tostring(os.clock())
do local f=io.open(BMF_DATA..'settings.json','rb');if f then local raw=f:read('*a');f:close();local ok=pcall(BMF._json.decode,raw);if ok then BMF._set('settings',raw)end end end
BMF._set('epoch',BMF_GENERATION);BMF._set('ids','[]');BMF._set('status',BMF._json.encode({ready=false,game='identifying',branch='unknown',profile='unknown'}))
BMF.RegisterMod{id='BladesongModFramework',name='Bladesong Mod Framework',author='Bladesong community',description='Shared compatibility layer and in-game mod manager',version=BMF.VERSION,api='^1.0.0',settings={auto_check={type='boolean',default=true},developer_mode={type='boolean',default=false},registry_url={type='string',default='https://raw.githubusercontent.com/LTR-JT/BladesongModFramework/main/mod-index.json'}}}
BMF_WORKER=assert(loadfile(BMF_ROOT..'worker_client.lua'))(BMF_ROOT,BMF)
BMF.StartJob=BMF_WORKER.StartJob
BMF_PollJobs=BMF_WORKER.Poll
print('[BMF] Quiet worker revision 2 active: direct CreateProcessW; shell launches disabled.\n')
BMF_MANAGER=assert(loadfile(BMF_ROOT..'manager.lua'))(BMF,BMF_ROOT)
BMF_MANAGER.PrimeCatalogue(BMF_MANAGER.default_index)
BMF_CREATIVE=assert(loadfile(BMF_ROOT..'ui/creative_host.lua'))(BMF,BMF_ROOT)
BMF.StartJob('discover',{},function(result)
 if result.last_apply and result.last_apply.status=='failed'then BMF_MANAGER.message='Previous change could not be applied: '..tostring(result.last_apply.error);print('[BMF] '..BMF_MANAGER.message..'\n')end
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
  BMF.Poll();BMF_MANAGER.Monitor();BMF_CREATIVE.Tick()
  local preferences=BMF.GetSettings('BladesongModFramework')
  if preferences.auto_check~=false and (not BMF_LAST_UPDATE_CHECK or os.time()-BMF_LAST_UPDATE_CHECK>=3600)then
   BMF_LAST_UPDATE_CHECK=os.time();BMF_MANAGER.CheckUpdates()
  end
  if not BMF_MANAGER.browse_requested then BMF_MANAGER.RefreshCatalogue(BMF_MANAGER.default_index,false)end
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
print('[BMF] Framework 0.1.7 initialized; API 1.0.0; branch identity is unknown until verified.\n')
