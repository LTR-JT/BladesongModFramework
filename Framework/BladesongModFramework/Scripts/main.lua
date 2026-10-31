-- Bladesong Mod Framework 0.1.8. All UObject access stays on the game thread.
if BMF_RUNTIME_STARTED then return end
BMF_RUNTIME_STARTED=true
BMF_ROOT=debug.getinfo(1,'S').source:gsub('^@',''):match('^(.*[\\/])')..'../../shared/BladesongFramework/'
BMF=assert(loadfile(BMF_ROOT..'api.lua'))(BMF_ROOT)
BMF_DATA=BMF_ROOT..'../../BladesongModFramework/Data/'
BMF_JOBS={};BMF_JOB_SEQUENCE=0;BMF_GENERATION=tostring(os.time())..':'..tostring(os.clock())
do local f=io.open(BMF_DATA..'settings.json','rb');if f then local raw=f:read('*a');f:close();local ok=pcall(BMF._json.decode,raw);if ok then BMF._set('settings',raw)end end end
BMF._set('epoch',BMF_GENERATION);BMF._set('ids','[]');BMF._set('status',BMF._json.encode({ready=false,game='identifying',branch='unknown',profile='unknown'}))
BMF.BindMod('BladesongModFramework')
BMF_WORKER=assert(loadfile(BMF_ROOT..'worker_client.lua'))(BMF_ROOT,BMF)
BMF.StartJob=BMF_WORKER.StartJob
BMF_CREATIVE=assert(loadfile(BMF_ROOT..'ui/creative_host.lua'))(BMF,BMF_ROOT)
BMF.StartJob('identify',{},function(result)
 if result.identity then
  local status=result.identity;status.ready=true;status.profile=nil
  BMF._set('status',BMF._json.encode(status));local patch=BMF._applyCompatibility();status.profile=patch.id;BMF._set('status',BMF._json.encode(status));print('[BMF] Compatibility patch '..patch.id..' branch='..status.branch..' status='..patch.status..'\n')
 else BMF.errors[#BMF.errors+1]=result.error or 'Build identification failed';BMF._set('status',BMF._json.encode({ready=true,game='unknown',branch='unknown',profile='unknown'}))end
end)
function BMF_RuntimeTick()
 if BMF._get('epoch')~=BMF_GENERATION then return end
 local ok,err=pcall(function()
  BMF.Poll();BMF_WORKER.Poll();BMF_CREATIVE.Tick()
  local settings=BMF._get('settings')or '{}'
  if settings~=BMF_SAVED_SETTINGS then
   BMF_SAVED_SETTINGS=settings;BMF.StartJob('settings',{settings=BMF._json.decode(settings)},function(result)if result.status=='failed'then BMF.errors[#BMF.errors+1]=result.error end end)
  end
 end)
 if not ok and tostring(err)~=BMF_LAST_ERROR then BMF_LAST_ERROR=tostring(err);BMF.errors[#BMF.errors+1]=BMF_LAST_ERROR;print('[BMF] '..BMF_LAST_ERROR..'\n')end
 ExecuteInGameThreadWithDelay(500,BMF_RuntimeTick)
end
ExecuteInGameThreadWithDelay(500,BMF_RuntimeTick)
print('[BMF] Framework 0.1.8 initialized; API 1.0.0; branch identity is unknown until verified.\n')
