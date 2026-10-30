local TEST_ROOT=os.getenv('BMF_TEST_ROOT')or 'BladesongModdingPlatform'
local root=TEST_ROOT..'/Framework/shared/BladesongFramework/'
local J=assert(loadfile(root..'json.lua'))();local V=assert(loadfile(root..'semver.lua'))()
assert(J.decode(J.encode({a='"\n',b=true,c={1,2,3}})).a=='"\n')
assert(not pcall(J.decode,'{"a":1,"a":2}'));assert(not pcall(J.decode,'[01]'));assert(not pcall(J.decode,'[1,]'))
assert(V.matches('1.2.3','^1.0.0')and not V.matches('2.0.0','^1.0.0'));assert(V.matches('1.2.3','>=1.1.0 <2.0.0'))
local shared={};ModRef={};function ModRef:GetSharedVariable(k)return shared[k]end;function ModRef:SetSharedVariable(k,v)assert(type(v)~='function'and type(v)~='table');shared[k]=v end
local function object(v)v=v or {};function v:IsValid()return true end;return v end
local sword=object();local forge=object();function forge:GetPiece()return sword end
local gm=object();function gm:GetForgeMode()return forge end
local utils=object();function utils:GetBladesongGameMode()return gm end;function utils:GetBladesongGameState()return object()end
local objects={['/Script/Bladesong.Default__BladesongUtils']=utils}
function StaticFindObject(p)return objects[p]end;function FindFirstOf(p)if p=='BladesongGameMode'then return gm end end
local F=assert(loadfile(root..'api.lua'))(root)
F._set('status',J.encode({ready=true,game='fixture',branch='unknown',profile='unknown'}))
assert(F.IsReady()and F.GetGameBranch()=='unknown'and not F.HasCapability('native.pcl'))
F.RegisterMod{id='test',name='Test',version='1.0.0',api='^1.0.0',dependencies={missing='^1.0.0'},settings={enabled={type='boolean',default=true}}}
assert(F.GetRegisteredMods()[1].status=='limited')
assert(not pcall(F.RegisterMod,{id='../bad',name='Bad',version='1.0.0'}))
assert(not pcall(F.RegisterMod,{id='badapi',name='Bad',version='1.0.0',api='^2.0.0'}))
F.SetSetting('test','enabled',false);assert(F.GetSettings('test').enabled==false)
assert(not pcall(F.SetSetting,'test','enabled','not boolean'))
local invoked=0;F.RegisterPage('testpage',{title='Test page'},function()invoked=invoked+1 end)
local second=assert(loadfile(root..'api.lua'))(root);second.SendPage('test','testpage');F.Poll();F.Poll();assert(invoked==1)
local function pcl_adapter()return F.GetCurrentSword()end
assert(pcl_adapter()==sword)
function forge:GetPieceV2()return sword end;forge.GetPiece=nil
assert(pcl_adapter()==nil)
F._map.functions.current_sword='GetPieceV2';assert(pcl_adapter()==sword)
F._map.functions.current_sword='Missing';assert(pcl_adapter()==nil)
print('PASS: JSON bounds, semver, registry/dependencies, typed settings, serialized messaging, duplicate delivery, unknown native-build gate and unchanged-PCL compatibility remapping')

local pending={};function ExecuteInGameThreadWithDelay(_,callback)pending[#pending+1]=callback end
F._set('status',J.encode({ready=false}));local ready=0;F.Ready(function()ready=ready+1 end);assert(ready==0 and #pending==1)
F._set('status',J.encode({ready=true}));table.remove(pending,1)();assert(ready==1 and #pending==0)
assert(V.compare('1.0.0-beta.2','1.0.0-beta.10')<0 and V.compare('1.0.0','1.0.0-beta.10')>0)
print('PASS: dependent readiness defers initialization and completes once; numeric prerelease precedence')
