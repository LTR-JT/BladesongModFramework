-- Public facades call services; game builds supply adapters; a future backend can replace UE4SS here.
local root,host=...
local T=assert(loadfile(root..'internal/translation.lua'))()
local S={backend={}}
function S.invoke(name,...)
 local args={...};local patch=host.profile()
 local ok,result,why=pcall(function()
  if S.backend[name]then return S.backend[name](table.unpack(args))end
  local recipe=(patch.operations or {})[name]
  if recipe then return T.run(recipe,host,args)end
  return host.service(name,table.unpack(args))
 end)
 if not ok then return nil,'unsupported service '..name..': '..tostring(result)end
 return result,why
end
function S.event(name,context,...)
 local args={...};local patch=host.profile()
 local spec=(patch.event_adapters or {})[name]
 local ok,c,a,n=pcall(T.event,spec,context,args)
 if not ok then return nil,nil,tostring(c)end
 return c,a,n or select('#',...)
end
return S
