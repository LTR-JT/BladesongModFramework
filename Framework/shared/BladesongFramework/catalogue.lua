-- These are the utilities shipped in the UE4SS distribution used by this platform.
-- Unknown/unmanaged mods remain in the main list; lack of metadata is not a category.
local bundled={BPML_GenericFunctions=true,BPModLoaderMod=true,CheatManagerEnablerMod=true,
 ConsoleCommandsMod=true,ConsoleEnablerMod=true,Keybinds=true,LineTraceMod=true,SplitScreenMod=true}
local C={}
function C.partition(mods)
 local community,utilities={},{}
 for _,mod in ipairs(mods)do
  local list=bundled[mod.id]and utilities or community
  list[#list+1]=mod
 end
 return community,utilities
end
return C
