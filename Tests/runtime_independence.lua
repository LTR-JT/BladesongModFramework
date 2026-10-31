-- Mocked UE4SS lifecycle; actual framework startup runs with optional manager imports forbidden.
local repo=assert(os.getenv('BMF_TEST_ROOT'))
local env=setmetatable({},{__index=_G});env._G=env
local state,operations={},{}
local F={VERSION='0.1.8',API_VERSION='1.0.0',errors={}}
F._json=assert(loadfile(repo..'/Framework/shared/BladesongFramework/json.lua'))()
function F._get(k)return state[k]end
function F._set(k,v)state[k]=v end
function F.BindMod(id)assert(id=='BladesongModFramework')end
function F._applyCompatibility()return{id='fixture',status='verified'}end
function F.Poll()end
local native_load=loadfile
function env.loadfile(path,...)
 assert(not path:find('BladesongModManager',1,true)and not path:find('manager.lua',1,true),'Runtime imported manager')
 if path:match('api.lua$')then return function()return F end end
 if path:match('worker_client.lua$')then return function()return{StartJob=function(op,args,callback)
  assert(op=='identify'or op=='settings','Runtime attempted management operation');operations[#operations+1]=op
  callback({identity={sha256='fixture',branch='unknown'},status='complete'})
 end,Poll=function()end}end end
 if path:match('creative_host.lua$')then return function()return{Tick=function()end}end end
 return native_load(path,...)
end
function env.ExecuteInGameThreadWithDelay(_,callback)env.tick=callback end
assert(native_load(repo..'/Framework/BladesongModFramework/Scripts/main.lua','t',env))()
assert(env.BMF_MANAGER==nil and state.status:find('"ready":true',1,true))
env.tick();assert(operations[1]=='identify'and operations[2]=='settings')
local manifest=io.open(repo..'/../PreconstructionLibrary/mod.json','rb');if manifest then local m=F._json.decode(manifest:read('*a'));manifest:close();assert(m.dependencies.BladesongModFramework and not m.dependencies.BladesongModManager)end
print('PASS: mocked framework lifecycle and PCL metadata require no manager; no network or deployment operation in runtime startup')

