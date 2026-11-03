-- In-process services run file I/O on a native background thread.
local root,F=...
local J=F._json
local C={jobs={},sequence=0}
local base=root..'../../BladesongModFramework/'

function C.StartJob(operation,args,callback)
 C.sequence=C.sequence+1
 local id='job_'..os.time()..'_'..math.floor(os.clock()*1000000)..'_'..C.sequence
 local path=base..id
 local ok,errorMessage=pcall(function()
  C.service=C.service or assert(package.loadlib(base..'Scripts/bmf-local-service.dll','bmf_local_service'))
  if operation=='settings' then
   local payload=J.encode(args.settings)
   assert(#payload<=1048576,'Settings size limit')
   local file=assert(io.open(path..'.settings.json','wb'))
   local written,why=file:write(payload)
   local closed,closeError=file:close()
   assert(written,why)
   assert(closed,closeError)
  end
  local wire=operation..'\0'..id..'\0'..(operation=='list-saves' and args.source or '')
  assert(#wire<=16000,'Local service request is too long')
  local arguments={#wire}
  for i=1,#wire do arguments[#arguments+1]=wire:byte(i) end
  assert(C.service(table.unpack(arguments))==1,'Could not start Framework local service')
 end)
 if not ok then
  os.remove(path..'.settings.json')
  callback({status='failed',error=tostring(errorMessage)})
  return id
 end
 C.jobs[id]={path=path,callback=callback,started=os.time()}
 if not C.polling and type(ExecuteInGameThreadWithDelay)=='function' then
  C.polling=true
  local function poll()
   C.Poll()
   if next(C.jobs) then ExecuteInGameThreadWithDelay(50,poll) else C.polling=false end
  end
  ExecuteInGameThreadWithDelay(50,poll)
 end
 return id
end

function C.Poll()
 for id,job in pairs(C.jobs) do
  local file=io.open(job.path..'.result.json','rb')
  local response
  if file then
   local wire=file:read('*a')
   file:close()
   local ok,value=pcall(J.decode,wire)
   response=ok and value or {status='failed',error='Invalid local service result'}
   os.remove(job.path..'.result.json')
   os.remove(job.path..'.settings.json')
  elseif os.time()-job.started>180 then
   response={status='failed',error='Framework local service timed out'}
  end
  if response then
   C.jobs[id]=nil
   local ok,why=pcall(job.callback,response)
   if not ok then F.errors[#F.errors+1]=tostring(why) end
  end
 end
end
return C
