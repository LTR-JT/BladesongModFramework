-- Frozen generation-1 surface. Future internals must preserve this facade, including raw-object returns.
local names={
 'GetFrameworkVersion','GetAPIVersion','GetGameVersion','GetGameBranch','GetCompatibilityProfile','IsReady',
 'HasCapability','ResolveObject','ResolveClass','GetGameState','GetGameMode','GetForge','GetCurrentSword',
 'GetSwordDesign','GetSwordComponents','RegisterMod','RegisterPage','Poll','SendPage','GetRegisteredMods',
 'ExportDiagnostics','GetSettings','SetSetting','Ready','GetNativeHelper','Subscribe','SetComponentTransform',
 'OpenCreativeLibrary','GetCompatibilityData'
}
return function(implementation)
 local facade={}
 for _,name in ipairs(names)do assert(type(implementation[name])=='function','Historical API missing: '..name);facade[name]=implementation[name]end
 facade.GetAPIVersion=function()return '1.0.0'end
 return facade
end
