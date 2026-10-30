local scripts=debug.getinfo(1,'S').source:gsub('^@',''):match('^(.*[\\/])')
local root=scripts..'../../shared/BladesongFramework/'
local ok,F=pcall(function()return assert(loadfile(root..'api.lua'))(root)end)
if not ok then print('[Example] Install BladesongModFramework first.\n');return end
F.Ready(function()
 local ok,err=pcall(function()
 -- Metadata is discovered automatically from mod.json.
 local subscribed,why=F.Subscribe('forge_enter',function()print('[ExampleEvents] Forge opened\n')end)
 if not subscribed then print('[ExampleEvents] '..tostring(why)..'\n')end
 end)
 if not ok then print('[Example] '..tostring(err)..'\n')end
end)
