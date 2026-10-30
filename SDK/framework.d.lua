---@meta
---@class BladesongFramework
local Framework = {}
---Runtime semantic version
---@return string
function Framework.GetFrameworkVersion() end
---Stable public API semantic version
---@return string
function Framework.GetAPIVersion() end
---Detected Steam build or executable version; unknown before identification
---@return string
function Framework.GetGameVersion() end
---main only with matching local Steam public-branch evidence; otherwise unknown
---@return string
function Framework.GetGameBranch() end
---Active fingerprint/capability profile; not a promise of universal compatibility
---@return string
function Framework.GetCompatibilityProfile() end
---Broker initialization readiness, not every capability
---@return boolean
function Framework.IsReady() end
---Probe a named reflected interface or exact native PCL fingerprint
---@param name string
---@return boolean
function Framework.HasCapability(name) end
---Resolve a centralized object alias
---@param name string
---@return UObject|nil, string|nil
function Framework.ResolveObject(name) end
---Resolve a centralized class alias
---@param name string
---@return UClass|nil, string|nil
function Framework.ResolveClass(name) end
---Read current BladesongGameState on game thread
---@param context UObject|nil
---@return UObject|nil, string|nil
function Framework.GetGameState(context) end
---Read current BladesongGameMode on game thread
---@param context UObject|nil
---@return UObject|nil, string|nil
function Framework.GetGameMode(context) end
---Read currently active native Forge through compatibility mapping
---@param context UObject|nil
---@return UObject|nil, string|nil
function Framework.GetForge(context) end
---Read Forge UPiece through mapped getter
---@param context UObject|nil
---@return UPiece|nil, string|nil
function Framework.GetCurrentSword(context) end
---Read the native FWeaponDesignDefinition view for a valid UPiece; reacquire it after transitions.
---@param sword UPiece
---@return FWeaponDesignDefinition|nil, string|nil
function Framework.GetSwordDesign(sword) end
---Publish bounded serializable registration metadata
---@param metadata BMFModMetadata
---@return boolean
function Framework.RegisterMod(metadata) end
---Register local callback and serialized menu metadata; functions stay local
---@param id string
---@param definition table
---@param callback function
---@return boolean
function Framework.RegisterPage(id, definition, callback) end
---Process one pending local page command; call from your game-thread lifecycle tick
---@return nil
function Framework.Poll() end
---Send serializable page-open command to registered mod context
---@param mod string
---@param page string
---@return boolean
function Framework.SendPage(mod, page) end
---Read registered metadata with dependency/capability failures
---@return table[]
function Framework.GetRegisteredMods() end
---Export minimal diagnostic JSON; caller supplies a diagnostics*.json path
---@param path string
---@return boolean
function Framework.ExportDiagnostics(path) end
---Read serialized registered mod settings; use schema defaults when absent
---@param id string
---@return table
function Framework.GetSettings(id) end
---Type-check and save registered setting through broker persistence
---@param id string
---@param key string
---@param value boolean|number|string|table
---@return boolean
function Framework.SetSetting(id, key, value) end
---Wait on bounded-frequency game-thread timer for broker readiness
---@param callback function
---@return nil
function Framework.Ready(callback) end
---Resolve PCL helper only on exact supported executable fingerprint
---@param name string
---@param directory string
---@return string|nil, string|nil
function Framework.GetNativeHelper(name, directory) end
---Subscribe once per client instance to a mapped Forge lifecycle event; callback remains local.
---@param event string
---@param callback function
---@return boolean|nil, string|nil
function Framework.Subscribe(event, callback) end
---Set a validated SceneComponent presentation transform. This does not serialize a sword design or commit part edits.
---@param component USceneComponent
---@param transform table
---@return boolean|nil, string|nil
function Framework.SetComponentTransform(component, transform) end
---Traverse the active Forge root part, slot children and free children with cycle/size guards. Refs stay local and transient.
---@param sword UPiece
---@return ASwordPartActor[]|nil, string|nil
function Framework.GetSwordComponents(sword) end
---Invoke native Creative Mode navigation from the existing main menu; does not choose a sword or load Forge.
---@return boolean|nil, string|nil
function Framework.OpenCreativeLibrary() end
---Returns a detached copy of selected executable patch metadata, or data scoped to a mod ID.
---@param mod_id string|nil
---@return table
function Framework.GetCompatibilityData(mod_id) end
---Binds runtime handlers using existing mod.json metadata; metadata-only discovery needs no registration.
---@param id string
---@return boolean|nil
function Framework.BindMod(id) end
---Returns a detached normalized sword record with schema_version, kind, name and part_count.
---@param sword UObject|nil
---@return table|nil
function Framework.GetSwordSnapshot(sword) end
---Synchronizes active Forge actors into the sword design through a build-specific service sequence.
---@param forge UObject|nil
---@return boolean|nil
function Framework.SynchronizeSword(forge) end
return Framework
