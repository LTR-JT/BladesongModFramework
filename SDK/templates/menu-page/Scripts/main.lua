local scripts=debug.getinfo(1,'S').source:gsub('^@',''):match('^(.*[\\/])')
local root=scripts..'../../shared/BladesongFramework/'
local ok,F=pcall(function()return assert(loadfile(root..'api.lua'))(root)end)
if not ok then print('[Example] Install BladesongModFramework first.\n');return end
F.Ready(function()
 local ok,err=pcall(function()
 assert(F.BindMod('ExamplePage'))
 F.RegisterPage('info',{title='Show example info'},function()print('[ExamplePage] Page request received in this mod state\n')end)
 local function poll()F.Poll();ExecuteInGameThreadWithDelay(500,poll)end;poll()
 end)
 if not ok then print('[Example] '..tostring(err)..'\n')end
end)
