-- Framework-owned JSON patch packs are selected by executable hash, never branch alone.
local root,J=...
local index={
 ['de710959ec9959eef9904ac4dee3763d94e92994e9b28e63baa5b50bae8993d5']='main-25431485.json',
 ['ab7ef68cf68f04fd8a405e437eec49b979f1f225ac4a799827ba27c776b4721e']='bleedingedge-25940006.json'
}
local P={}
function P.select(identity)
 local hash=tostring(identity.sha256 or ''):lower()
 local file=index[hash]
 if not file then return {schema_version=1,id='unknown',branch='unknown',status='Unrecognized executable; reflected capability probes only',overrides={},native_helpers={}}end
 local f=assert(io.open(root..'compat/builds/'..file,'rb'),'Compatibility patch pack missing')
 local raw=f:read(262145);f:close();assert(#raw<=262144,'Compatibility patch pack too large')
 local patch=J.decode(raw)
 assert(patch.schema_version==1 and patch.sha256==hash,'Compatibility patch fingerprint/schema mismatch')
 assert(patch.branch=='main'or patch.branch=='bleedingedge','Invalid patch branch')
 if identity.branch~='unknown'and identity.branch~=nil and identity.branch~=patch.branch then
  return {schema_version=1,id='unknown',branch=identity.branch,status='Executable and branch evidence disagree',overrides={},native_helpers={}}
 end
 for category,values in pairs(patch.overrides or {})do
  assert(({objects=true,classes=true,functions=true,events=true,capabilities=true,properties=true})[category],'Invalid mapping category')
  for key,value in pairs(values)do assert(type(key)=='string'and(type(value)=='string'or value==false),'Invalid mapping override')end
 end
 for name,helper in pairs(patch.native_helpers or {})do
  assert(name:match('^[%w_%-]+%.dll$')and type(helper)=='table','Invalid native helper entry')
  if helper.path then assert(helper.path:match('^native/[%w_%-]+/[%w_%-]+%.dll$'),'Invalid framework helper path')end
 end
 return patch
end
return P
