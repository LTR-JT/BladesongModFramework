-- File snapshots are cheap; thumbnail decoding and game objects are kept out of this module.
local C={modes={}}
local function read(path)local file=io.open(path,'rb');if not file then return ''end;local wire=file:read('*a');file:close();return wire end
local function decode(value)return value:gsub('%%(%x%x)',function(hex)return string.char(tonumber(hex,16))end)end
function C.entries(mode,directory,index_path)
 local index,names=read(index_path),read(directory..'names.index')
 local old=C.modes[mode]
 if old and old.directory==directory and old.index==index and old.names==names then return old.entries,old end
 local metadata={}
 for line in (names..'\n'):gmatch('(.-)\r?\n')do
  local code,custom,original=line:match('^([^\t]+)\t([^\t]*)\t([^\t]*)$')
  if code then metadata[decode(code)]={custom=decode(custom),original=decode(original)}end
 end
 local entries,seen={},{}
 for line in (index..'\n'):gmatch('(.-)\r?\n')do
  local code=line:match('^%s*(.-)%s*$'):gsub('^\239\187\191','')
  if code~=''and code:sub(1,1)~='#'and code:sub(1,1)~=';'and not code:match('^PCL_LIBRARY_INDEX_V%d+$')and not code:match('^FString:%s*%x+$')and not seen[code]then
   seen[code]=true;local data=metadata[code]or {};local name=data.custom~=''and data.custom or nil;name=name or(data.original~=''and data.original or nil)or code
   entries[#entries+1]={code=code,mode=mode,name=name}
  end
 end
 local snapshot={directory=directory,index=index,names=names,entries=entries};C.modes[mode]=snapshot
 return entries,snapshot
end
return C
