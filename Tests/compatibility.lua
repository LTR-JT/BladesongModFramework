local TEST_ROOT=os.getenv('BMF_TEST_ROOT')or 'BladesongModdingPlatform'
local root=TEST_ROOT..'/Framework/shared/BladesongFramework/'
local J=assert(loadfile(root..'json.lua'))()
local shared={};ModRef={}
function ModRef:GetSharedVariable(k)return shared[k]end
function ModRef:SetSharedVariable(k,v)shared[k]=v end
local function object(o)o=o or {};function o:IsValid()return true end;return o end
local sword=object();local forge=object();function forge:GetPiece()return sword end;function forge:GetPieceV2()return sword end
local gm=object();function gm:GetForgeMode()return forge end
function FindFirstOf(name)if name=='BladesongGameMode'then return gm end end
function StaticFindObject()return object()end
local F=assert(loadfile(root..'api.lua'))(root)
local main='de710959ec9959eef9904ac4dee3763d94e92994e9b28e63baa5b50bae8993d5'
local edge='ab7ef68cf68f04fd8a405e437eec49b979f1f225ac4a799827ba27c776b4721e'
local function identify(hash,branch)F._set('status',J.encode({ready=true,sha256=hash,branch=branch}))end
identify(main,'main');assert(F.GetCompatibilityProfile()=='main-25431485'and F.HasCapability('native.pcl'))
assert(F.GetNativeHelper('fixture.dll','legacy/')=='legacy/fixture.dll')
assert(F.GetCompatibilityData('PreconstructionLibraryProbe').reflected_layouts.FSwordPartData.fields.bHasPrimarySlot.offset==0xD9)
identify(edge,'bleedingedge');assert(F.GetCompatibilityProfile()=='bleedingedge-25940006'and not F.HasCapability('native.pcl'))
assert(F.GetNativeHelper('fixture.dll','legacy/')==nil)
assert(F.GetNativeHelper('pcl_blade_library_151761.dll')==root..'native/25940006/pcl_blade_library_151761.dll')
assert(F.GetNativeHelper('pcl_native_seam.dll','legacy/')==nil) -- historical unsupported native paths stay blocked
assert(F.GetCompatibilityData('PreconstructionLibraryProbe').reflected_layouts.FSwordPartData.fields.bHasPrimarySlot.offset==0xDB)
local p=F.GetCompatibilityData();p.id='corrupted';assert(F.GetCompatibilityData().id=='bleedingedge-25940006')
assert(next(F.GetCompatibilityData('ExampleMod'))==nil)
identify('unknown','bleedingedge');assert(F.GetCompatibilityProfile()=='unknown'and not F.HasCapability('native.pcl'))
identify(main,'bleedingedge');assert(F.GetCompatibilityProfile()=='unknown'and not F.HasCapability('native.pcl'))
-- Controlled JSON-pack update redirects the unchanged dependent mod's API call.
local original_open=io.open
local fixture=J.decode(assert(original_open(root..'compat/builds/bleedingedge-25940006.json','rb')):read('*a'))
fixture.overrides={functions={current_sword='GetPieceV2'}}
fixture.mod_data={ExampleMod={feature='branch-specific'}}
fixture.native_helpers={['fixture.dll']={verified=true,path='native/bleedingedge/fixture.dll'}}
io.open=function(path,mode)
 if path==root..'compat/builds/bleedingedge-25940006.json'then return {read=function()return J.encode(fixture)end,close=function()end}end
 return original_open(path,mode)
end
identify(edge,'bleedingedge');forge.GetPiece=nil
assert(F.GetCurrentSword()==sword)
assert(F.GetCompatibilityData('ExampleMod').feature=='branch-specific')
assert(F.GetNativeHelper('fixture.dll')==root..'native/bleedingedge/fixture.dll')
identify(main,'main');assert(F.GetCurrentSword()==nil and F.GetCompatibilityData('ExampleMod').feature==nil)
io.open=original_open
print('PASS: exact fingerprint/branch selection; cross-branch native fallback denied; isolated mod data; JSON overrides update unchanged dependent adapters')
