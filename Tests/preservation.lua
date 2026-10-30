local TEST_ROOT=os.getenv('BMF_TEST_ROOT')or 'BladesongModdingPlatform'
local root=TEST_ROOT..'/Framework/shared/BladesongFramework/'
local J=assert(loadfile(root..'json.lua'))();local store={};ModRef={}
function ModRef:GetSharedVariable(k)return store[k]end
function ModRef:SetSharedVariable(k,v)store[k]=v end
local function object(t)t=t or {};function t:IsValid()return true end;return t end
local sword=object({Name='Preserved sword',WeaponDesignDefinition={AppliedSwordParts={1,2}}})
local forge=object();function forge:GetPiece()return sword end
local gm=object();function gm:GetForgeMode()return forge end
function FindFirstOf(name)if name=='BladesongGameMode'then return gm end end
function StaticFindObject()return object()end
local F=assert(loadfile(root..'api.lua'))(root)
local frozen=assert(loadfile(TEST_ROOT..'/Tests/frozen/sdk1/mod.lua'))()
local facade=assert(loadfile(root..'contracts/v1.lua'))()(F)
local main='de710959ec9959eef9904ac4dee3763d94e92994e9b28e63baa5b50bae8993d5'
local edge='ab7ef68cf68f04fd8a405e437eec49b979f1f225ac4a799827ba27c776b4721e'
for _,identity in ipairs({{main,'main'},{edge,'bleedingedge'}})do
 F._set('status',J.encode({sha256=identity[1],branch=identity[2],ready=true}))
 assert(frozen(facade).part_count==2)
end
local old_open=io.open
local patch=J.decode(assert(old_open(root..'compat/builds/bleedingedge-25940006.json')):read('*a'))
patch.overrides.properties={weapon_design='ReorganizedDesign'}
patch.operations={
 ['sword.current']={steps={
  {id='manager',op='resolve',alias='utils'},
  {id='wrapper',op='call',target='manager',method='FindConstruction',args={{literal='sword'},{literal=true}}},
  {id='context',op='get',target='wrapper',property='Context'},
  {id='wrapped',op='call',target='context',method='ReadItem',args={{literal=7},{literal='active'}}}
 },result={var='wrapped',path={'Payload','Item'}}},
 ['sword.design']={steps={
  {id='manager',op='resolve',alias='utils'},
  {id='data',op='call',target='manager',method='GetDesign',args={{input=1}}},
  {id='legacy',op='record',fields={AppliedSwordParts={var='data',path={'Nodes'}}}}
 },result={var='legacy'}}
}
patch.event_adapters={forge_enter={context={input=2},args={{input=1,path={'reason'}}}}}
io.open=function(path,mode)if path==root..'compat/builds/bleedingedge-25940006.json'then return {read=function()return J.encode(patch)end,close=function()end}end;return old_open(path,mode)end
local provider=object();local context=object()
function provider:FindConstruction(kind,include)assert(kind=='sword'and include);return {Context=context}end
function context:ReadItem(index,which)assert(index==7 and which=='active');return {Payload={Item=sword}}end
function provider:GetDesign(item)assert(item==sword);return {Nodes={1,2}}end
function StaticFindObject()return provider end
F._set('status',J.encode({sha256=main,branch='main',ready=true}));F.GetCompatibilityData()
F._set('status',J.encode({sha256=edge,branch='bleedingedge',ready=true}))
forge.GetPiece=nil;gm.GetForgeMode=nil;sword.WeaponDesignDefinition=nil
assert(frozen(facade).part_count==2) -- identical frozen source and facade
local c,args,n=F._services.event('forge_enter',provider,{reason='loaded'},context)
assert(c==context and n==1 and args[1]=='loaded')
-- Internal backend can be replaced without changing SDK consumer code.
F._services.backend['sword.current']=function()return sword end
assert(frozen(facade).sword==sword)
io.open=old_open
F.API_VERSION='5.0.0';F.RegisterMod{id='FrozenSDK1',name='Frozen',version='1.0.0',api='^1.0.0'}
assert(facade.GetAPIVersion()=='1.0.0')
local preserved=assert(loadfile(root..'sdk.lua'))(root,'=1.0.0')
assert(type(preserved.GetCurrentSword)=='function')
assert(not pcall(assert(loadfile(root..'sdk.lua')),root,'^9.0.0'))
print('PASS: frozen SDK1 mod across Main/BE fixtures, reorganized ownership/subsystem, reordered/new arguments, wrapped returns, legacy structure/event translation and replaceable backend')

local legacy=assert(io.open(TEST_ROOT..'/Tests/frozen/legacy-settings.json','rb'));F._set('settings',legacy:read('*a'));legacy:close()
assert(F.GetSettings('LegacyData').saved.count==3 and F.GetSettings('LegacyData').saved.label=='preserved')
print('PASS: legacy per-mod settings JSON remains readable without rewriting')

local T=assert(loadfile(root..'internal/translation.lua'))()
local target=object();function target:Flip(flag)assert(flag==false);return true end
local output=T.run({steps={{id='object',op='resolve',alias='fixture'},{id='result',op='call',target='object',method='Flip',args={{input=1}}}},result={var='result'}},{resolve=function()return target end,valid=function()return true end},{false})
assert(output==true);print('PASS: false arguments survive conversion without becoming nil')

local snapshot=assert(F.GetSwordSnapshot(sword));assert(snapshot.name=='Preserved sword'and snapshot.part_count==2 and snapshot.kind=='sword')
for _,v in pairs(snapshot)do assert(type(v)=='string'or type(v)=='number')end
local invalid={IsValid=function()return false end};assert(F.GetSwordSnapshot(invalid)==nil)
print('PASS: normalized snapshot contains only detached scalar data; invalid lifetime rejected')
