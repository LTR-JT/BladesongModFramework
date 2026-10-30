local root=os.getenv('BMF_TEST_ROOT')or 'BladesongModdingPlatform'
local M,F,text=assert(loadfile(root..'/Tests/manager_open.lua'))()
local jobs,settings={},{}
function F.GetSettings()return {registry_url=''}end
function F.SetSetting(id,key,value)assert(type(value)=='string','FString escaped UI conversion');settings[key]=value end
function F.StartJob(operation,args,callback)jobs[#jobs+1]={operation=operation,args=args,callback=callback}end
function text:Conv_TextToString(value)return {ToString=function()return value end}end
M.Open();M.page='browse';M.Render()
assert(#jobs==1 and jobs[1].operation=='browse')
assert(jobs[1].args.index_url==M.default_index and settings.registry_url==M.default_index)
jobs[1].callback({status='complete',entries={{name='Preconstruction Library',repository='https://github.com/LTR-JT/PreconstructionLibrary',manifest={name='Preconstruction Library',version='15.18.2'}}}})
assert(not M.busy and #M.browser==1 and #jobs==1)
local install
for _,action in pairs(M.actions)do if action.widget.caption=='Install'then install=action end end
assert(install,'Browse entry has no Install button');install.callback()
assert(M.page=='browse'and jobs[#jobs].operation=='inspect','Browse install left the catalogue')
jobs[#jobs].callback({status='complete',mod={id='PreconstructionLibraryProbe',name='Preconstruction Library',version='15.18.2',source='https://example.org/mod.json',manifest_sha256='fixture'}})
local confirm
for _,action in pairs(M.actions)do if action.widget.caption=='Confirm install'then confirm=action end end
assert(confirm,'Reviewed release has no confirmation button')
confirm.callback();assert(jobs[#jobs].operation=='stage');jobs[#jobs].callback({status='complete',message='Staged'})
local restart
for _,entry in pairs(M.actions)do if entry.widget.caption=='Restart & Apply'then restart=entry end end
assert(restart,'Staged browse installation has no apply control');restart.callback()
local confirmation
for _,entry in pairs(M.actions)do if entry.widget.caption=='Confirm saved - restart and apply'then confirmation=entry end end
assert(confirmation,'Apply requires explicit saved-game confirmation')
jobs={}
M.registry:SetText('https://example.org/index.json')
for _,action in pairs(M.actions)do if action.widget.caption=='Refresh catalogue'then action.callback();break end end
assert(#jobs==1 and jobs[1].args.index_url=='https://example.org/index.json')
jobs[1].callback({status='failed',error='Offline'})
M.page='install';M.Render();M.url:SetText('https://github.com/LTR-JT/PreconstructionLibrary')
for _,action in pairs(M.actions)do if action.widget.caption=='Inspect URL'then action.callback();break end end
assert(#jobs==2 and type(jobs[2].args.url)=='string')
M.Close()
print('PASS: blank index migrates to hosted default, Browse auto-loads once, FString URL becomes Lua string, offline errors stop retries, install URL stays serializable')
