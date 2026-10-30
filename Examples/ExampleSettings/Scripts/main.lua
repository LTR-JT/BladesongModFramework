local scripts=debug.getinfo(1,'S').source:gsub('^@',''):match('^(.*[\\/])')
local root=scripts..'../../shared/BladesongFramework/'
local ok,F=pcall(function()return assert(loadfile(root..'api.lua'))(root)end)
if not ok then print('[Example] Install BladesongModFramework first.\n');return end
F.Ready(function()
 local ok,err=pcall(function()
 -- Metadata is discovered automatically from mod.json.
 local value=F.GetSettings('ExampleSettings').enabled;if value==nil then value=true end
 print('[ExampleSettings] enabled='..tostring(value)..'\n')
 end)
 if not ok then print('[Example] '..tostring(err)..'\n')end
end)
