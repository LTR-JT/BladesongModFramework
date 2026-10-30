-- Portable bounded translation primitives. No UE4SS imports, memory addresses or mod code execution.
local T={}
local unpack=table.unpack or unpack
local function value(spec,vars,args)
 if spec.input or spec.var then
  local v;if spec.input then v=args[spec.input]else v=vars[spec.var]end
  for _,key in ipairs(spec.path or {})do if v==nil then return nil end;v=v[key]end
  return v
 end
 return spec.literal
end
function T.run(recipe,host,args)
 assert(type(recipe)=='table'and type(recipe.steps)=='table'and #recipe.steps<=32,'Invalid translation recipe')
 local vars={}
 for _,step in ipairs(recipe.steps)do
  assert(type(step.id)=='string','Translation step id required')
  if step.op=='resolve'then vars[step.id]=host.resolve(step.kind or 'object',step.alias)
  elseif step.op=='service'then vars[step.id]=host.service(step.name)
  elseif step.op=='get'then
   local target=vars[step.target];if target==nil or(type(target)~='table'and not host.valid(target))then return nil,'object unavailable'end
   vars[step.id]=target[step.property]
  elseif step.op=='record'then
   local record={};for key,spec in pairs(step.fields or {})do record[key]=value(spec,vars,args)end;vars[step.id]=record
  elseif step.op=='call'then
   local target=vars[step.target];if not host.valid(target)then return nil,'object unavailable'end
   local av={};for i,spec in ipairs(step.args or {})do av[i]=value(spec,vars,args)end
   assert(#(step.args or {})<=16,'Translation argument limit')
   vars[step.id]=target[step.method](target,unpack(av,1,#(step.args or {})))
  else error('Unsupported translation operation')end
 end
 return value(recipe.result or {},vars,args)
end
function T.event(spec,context,args)
 if not spec then return context,args end
 local vars={context=context};local out={}
 for i,arg in ipairs(spec.args or {})do out[i]=value(arg,vars,args)end
 return spec.context and value(spec.context,vars,args)or context,out,#(spec.args or {})
end
return T
