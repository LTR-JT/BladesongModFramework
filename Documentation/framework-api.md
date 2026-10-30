# Framework API

Generated from the implementation-checked public contract. Types refer to UE4SS proxies, not transferable cross-state objects.

## GetFrameworkVersion

Runtime semantic version

Parameters: none.

Returns: `string`.

Errors: None.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.GetFrameworkVersion()

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## GetAPIVersion

Stable public API semantic version

Parameters: none.

Returns: `string`.

Errors: None.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.GetAPIVersion()

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## GetGameVersion

Detected Steam build or executable version; unknown before identification

Parameters: none.

Returns: `string`.

Errors: None.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.GetGameVersion()

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## GetGameBranch

main only with matching local Steam public-branch evidence; otherwise unknown

Parameters: none.

Returns: `string`.

Errors: None.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.GetGameBranch()

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## GetCompatibilityProfile

Active fingerprint/capability profile; not a promise of universal compatibility

Parameters: none.

Returns: `string`.

Errors: None.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.GetCompatibilityProfile()

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## IsReady

Broker initialization readiness, not every capability

Parameters: none.

Returns: `boolean`.

Errors: None.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.IsReady()

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## HasCapability

Probe a named reflected interface or exact native PCL fingerprint

Parameters: name.

Returns: `boolean`.

Errors: Unknown capability returns false.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.HasCapability("forge.read")

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## ResolveObject

Resolve a centralized object alias

Parameters: name.

Returns: `UObject|nil, string|nil`.

Errors: nil,error for unavailable/unknown alias.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.ResolveObject("utils")

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## ResolveClass

Resolve a centralized class alias

Parameters: name.

Returns: `UClass|nil, string|nil`.

Errors: nil,error for unavailable/unknown alias.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.ResolveClass("sword")

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## GetGameState

Read current BladesongGameState on game thread

Parameters: context.

Returns: `UObject|nil, string|nil`.

Errors: nil,error if unavailable.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.GetGameState()

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## GetGameMode

Read current BladesongGameMode on game thread

Parameters: context.

Returns: `UObject|nil, string|nil`.

Errors: nil,error if unavailable.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.GetGameMode()

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## GetForge

Read currently active native Forge through compatibility mapping

Parameters: context.

Returns: `UObject|nil, string|nil`.

Errors: nil,error when Forge is closed.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.GetForge()

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## GetCurrentSword

Read Forge UPiece through mapped getter

Parameters: context.

Returns: `UPiece|nil, string|nil`.

Errors: nil,error outside Forge or missing interface.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.GetCurrentSword()

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## GetSwordDesign

Read the native FWeaponDesignDefinition view for a valid UPiece; reacquire it after transitions.

Parameters: sword.

Returns: `FWeaponDesignDefinition|nil, string|nil`.

Errors: nil,error for invalid sword or unavailable struct.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.GetSwordDesign(sword)

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## RegisterMod

Publish bounded serializable registration metadata

Parameters: metadata.

Returns: `boolean`.

Errors: Assertion for malformed id/version/API/JSON or missing UE4SS ModRef.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.RegisterMod{ id="Hello", name="Hello", version="1.0.0", api="^1.0.0" }

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## RegisterPage

Register local callback and serialized menu metadata; functions stay local

Parameters: id, definition, callback.

Returns: `boolean`.

Errors: Assertion when mod is not registered or callback/definition invalid.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.RegisterPage("info", {title="Info"}, function() print("Opened") end)

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## Poll

Process one pending local page command; call from your game-thread lifecycle tick

Parameters: none.

Returns: `nil`.

Errors: Callback errors recorded in diagnostics.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.Poll()

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## SendPage

Send serializable page-open command to registered mod context

Parameters: mod, page.

Returns: `boolean`.

Errors: Assertion on invalid argument type; one pending command per mod.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.SendPage("Hello", "info")

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## GetRegisteredMods

Read registered metadata with dependency/capability failures

Parameters: none.

Returns: `table[]`.

Errors: Malformed remote registrations ignored.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.GetRegisteredMods()

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## ExportDiagnostics

Export minimal diagnostic JSON; caller supplies a diagnostics*.json path

Parameters: path.

Returns: `boolean`.

Errors: Assertion on path suffix/file I/O failure.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.ExportDiagnostics("diagnostics.json")

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## GetSettings

Read serialized registered mod settings; use schema defaults when absent

Parameters: id.

Returns: `table`.

Errors: Assertion on invalid mod id.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.GetSettings("Hello")

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## SetSetting

Type-check and save registered setting through broker persistence

Parameters: id, key, value.

Returns: `boolean`.

Errors: Assertion for unknown setting or incorrect type.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.SetSetting("Hello", "enabled", true)

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## Ready

Wait on bounded-frequency game-thread timer for broker readiness

Parameters: callback.

Returns: `nil`.

Errors: Assertion without scheduler; callback stays in caller state.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.Ready(function() print("Framework ready") end)

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## GetNativeHelper

Resolve PCL helper only on exact supported executable fingerprint

Parameters: name, directory.

Returns: `string|nil, string|nil`.

Errors: nil,error on unknown native build; malformed names assert.

Since API 1.0.0. Reflected APIs require their capability; native helpers require exact fingerprint. Main baseline known; framework branch testing tracked separately.

```lua

Framework.GetNativeHelper("pcl_local_cache_151733.dll", scripts_dir)

```

Game references are transient. Reacquire after transitions. Public SDK 1.0 contract is preview until live migration passes.

## Subscribe

Subscribe once per client instance to a mapped Forge lifecycle event; callback remains local.

Parameters: event, callback.

Returns: `boolean|nil, string|nil`.

Errors: nil,error for unsupported capability/invalid input; bad callback type asserts.

Since API 1.0.0. Capability-probed reflected APIs. Unknown builds remain unverified.

```lua

Framework.Subscribe("forge_enter", function() print("Forge entered") end)

```

Game-thread callers only. Presentation transforms do not imply persistent construction edits. Examples require a real current component/transform, not a fabricated sword array.

## SetComponentTransform

Set a validated SceneComponent presentation transform. This does not serialize a sword design or commit part edits.

Parameters: component, transform.

Returns: `boolean|nil, string|nil`.

Errors: nil,error for unsupported capability/invalid input; bad callback type asserts.

Since API 1.0.0. Capability-probed reflected APIs. Unknown builds remain unverified.

```lua

local ok, error = Framework.SetComponentTransform(component, transform)

```

Game-thread callers only. Presentation transforms do not imply persistent construction edits. Examples require a real current component/transform, not a fabricated sword array.

## GetSwordComponents

Traverse the active Forge root part, slot children and free children with cycle/size guards. Refs stay local and transient.

Parameters: sword.

Returns: `ASwordPartActor[]|nil, string|nil`.

Errors: nil,error outside active Forge or if part traversal is unsupported.

Since API 1.0.0. Requires forge.parts reflected capability and the currently active UPiece.

```lua

local parts, error = Framework.GetSwordComponents(sword)

```

Returns current part actors, not a persistent snapshot or blade mesh. Reacquire after transitions; do not hold native pointers in asynchronous jobs.

## OpenCreativeLibrary

Invoke native Creative Mode navigation from the existing main menu; does not choose a sword or load Forge.

Parameters: none.

Returns: `boolean|nil, string|nil`.

Errors: nil,error when main menu/native button capability unavailable.

Since API 1.0.0. Requires native CommonButtonBase click capability and live WBP_MainMenu.

```lua

local ok, error = Framework.OpenCreativeLibrary()

```

Game-thread UI call; navigation completes asynchronously. No guarantee that a particular feature panel is ready immediately.

## GetCompatibilityData

Returns a detached copy of selected executable patch metadata, or data scoped to a mod ID.

Parameters: mod_id.

Returns: `table`.

Errors: Invalid mod ID raises an error; unknown executables return an unknown profile and empty mod data..

Since API 1.0.0. Exact SHA256 selects Main or Bleeding Edge patch packs. Branch labels alone never select native patches.

```lua

local patch = Framework.GetCompatibilityData()
local own = Framework.GetCompatibilityData("ExampleMod")

```

Native helpers must be explicitly verified for the selected executable. Metadata identification does not certify gameplay behavior.

## BindMod

Binds runtime handlers using existing mod.json metadata; metadata-only discovery needs no registration.

Parameters: id.

Returns: `boolean|nil`.

Errors: Returns nil and a stable reason when the required game service is unavailable; invalid IDs raise validation errors..

Since API 1.0.0 additive preview. Backend is selected centrally; no branch-specific code belongs in the consuming mod.

```lua

assert(Framework.BindMod("ExampleMod"))

```

Legacy raw-object APIs are preserved; transient Unreal objects require validity checks. The new services have simulated regression coverage, not blanket live gameplay certification.

## GetSwordSnapshot

Returns a detached normalized sword record with schema_version, kind, name and part_count.

Parameters: sword.

Returns: `table|nil`.

Errors: Returns nil and a stable reason when the required game service is unavailable; invalid IDs raise validation errors..

Since API 1.0.0 additive preview. Backend is selected centrally; no branch-specific code belongs in the consuming mod.

```lua

local sword, reason = Framework.GetSwordSnapshot()

```

Legacy raw-object APIs are preserved; transient Unreal objects require validity checks. The new services have simulated regression coverage, not blanket live gameplay certification.

## SynchronizeSword

Synchronizes active Forge actors into the sword design through a build-specific service sequence.

Parameters: forge.

Returns: `boolean|nil`.

Errors: Returns nil and a stable reason when the required game service is unavailable; invalid IDs raise validation errors..

Since API 1.0.0 additive preview. Backend is selected centrally; no branch-specific code belongs in the consuming mod.

```lua

local ok, reason = Framework.SynchronizeSword()

```

Legacy raw-object APIs are preserved; transient Unreal objects require validity checks. The new services have simulated regression coverage, not blanket live gameplay certification.
