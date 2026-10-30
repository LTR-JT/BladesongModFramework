local scripts=debug.getinfo(1,'S').source:gsub('^@',''):match('^(.*[\\/])')
local root=scripts..'../../shared/BladesongFramework/'
local ok,F=pcall(function()return assert(loadfile(root..'api.lua'))(root)end)
if not ok then print('[Example] Install BladesongModFramework first.\n');return end
F.Ready(function()
 local ok,err=pcall(function()
 -- Metadata is discovered automatically from mod.json.
 RegisterKeyBind(Key.F8,function()ExecuteInGameThread(function()local sword,why=F.GetSwordSnapshot();print('[ExampleSwordReader] '..(sword and sword.name..' ('..sword.part_count..' parts)'or tostring(why))..'\n')end)end)
 end)
 if not ok then print('[Example] '..tostring(err)..'\n')end
end)
