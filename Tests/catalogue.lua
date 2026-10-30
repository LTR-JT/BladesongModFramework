local TEST_ROOT=os.getenv('BMF_TEST_ROOT')or 'BladesongModdingPlatform'
local C=assert(loadfile(TEST_ROOT..'/Framework/shared/BladesongFramework/catalogue.lua'))()
local mods={{id='ConsoleCommandsMod'},{id='PreconstructionLibraryProbe'},
 {id='BladesongModFramework'},{id='OtherCommunityMod',discovered=true},{id='BPModLoaderMod'}}
local community,utilities=C.partition(mods)
assert(#community==3 and #utilities==2)
assert(community[1]==mods[2] and community[3]==mods[4])
assert(utilities[1]==mods[1] and utilities[2]==mods[5])
print('PASS: bundled utilities grouped; PCL, framework and unknown community mods remain visible')
