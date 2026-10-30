local root=os.getenv('BMF_TEST_ROOT')or 'BladesongModdingPlatform'
local shared=root..'/Framework/shared/BladesongFramework/'
function RegisterHook()end
local mods,visits={},{count=0}
local F={}
function F._valid(o)return type(o)=='table'end
function F.IsReady()return true end
function F.GetRegisteredMods()return mods end
local host=assert(loadfile(shared..'ui/creative_host.lua'))(F,shared)
assert(_G.pcl151762_create_home==nil,'Default framework host leaked PCL globals')
local names={};for _,tab in ipairs(host.environment.PCL_FOLDER_TABS.list())do names[tab.id]=true end
assert(names.creative and names.story and not names.preconstruction)
host.environment.pcl151762_monitor_home=function()visits.count=visits.count+1 end
host.Tick();assert(visits.count==1)
mods={{id='PreconstructionLibraryProbe',enabled=true}};host.Tick();assert(visits.count==1)
mods={{id='PreconstructionLibraryProbe',enabled=false}};host.Tick();assert(visits.count==2)
local provider=setmetatable({pcl151112_script_dir=function()return 'not-an-installed-mod/'end},{__index=_G})
local addon=assert(loadfile(shared..'ui/creative_host.lua'))(F,shared,provider,{provider=true,is_valid=F._valid,log=function()end})
names={};for _,tab in ipairs(addon.environment.PCL_FOLDER_TABS.list())do names[tab.id]=true end
assert(names.creative and names.story and names.preconstruction)
local p=root..'/../PreconstructionLibrary/Source/PreconstructionLibraryProbe/Scripts/pcl_runtime.lua'
local file=io.open(p,'rb')
if file then
 local source=file:read('*a');file:close()
 assert(not source:find('function pcl151762_create_home',1,true)and not source:find('function pcl151762_mount_folder_tabs',1,true))
 assert(source:find("ui/creative_host.lua",1,true))
end
print('PASS: framework owns Creative/Story UI without PCL; enabled provider adds library tab; disabled PCL leaves core available; PCL runtime contains no Creative layout implementation')

-- Framework-only screens have no provider tab: opacity updates must tolerate it.
host.environment.pcl151762_action_opacity({action_visuals={}},nil,.4)
