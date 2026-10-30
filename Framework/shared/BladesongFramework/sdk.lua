-- Explicit contract loader. Existing api.lua imports continue to work unchanged.
local root,requested,mod_id=...
local F=assert(loadfile(root..'api.lua'))(root)
local version=assert(loadfile(root..'semver.lua'))()
assert(version.matches('1.0.0',requested or '^1.0.0'),'Unsupported historical SDK contract')
if mod_id then F.BindMod(mod_id)end
local facade=assert(loadfile(root..'contracts/v1.lua'))()(F)
-- Additive services do not alter any frozen generation-1 signatures or return values.
facade.GetSwordSnapshot=F.GetSwordSnapshot
facade.BindMod=F.BindMod
facade.SynchronizeSword=F.SynchronizeSword
return facade
