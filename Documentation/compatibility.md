# Compatibility maintenance

The shared mapping is compat/shared.lua. Profiles have explicit evidence and separate Main, Bleeding Edge and unknown directories. Empty overrides mean no branch-specific difference has been verified; they are not claims that both branches work.

The worker computes the executable SHA256 and reads the Steam build/branch only when the installation path matches the local app manifest. An observed public BetaKey maps to Main; bleedingedge maps to Bleeding Edge. Other values stay unknown. Engine version, a UFunction name, or loading successfully does not establish branch identity.

Unknown executables keep available reflected capabilities and disable PCL raw native loading. The existing native binaries retain their own prologue/object guards as a second boundary. Never enable a fingerprint merely to silence a failure; verify the native ABI first.

Tests/core.lua changes the framework's current_sword mapping from GetPiece to GetPieceV2 and reuses the same dependent adapter. This is the controlled compatibility test. It proves mapping centralization for that behavior, not that arbitrary breaking updates need no dependent-mod changes.

Use Tools/game_reference.py extract on each local CXXHeaderDump, then compare the two JSON outputs. The report identifies added/removed classes, changed properties, changed function signatures and base types. Asset-path changes need separate evidence; class-name differences alone cannot prove them.

Before releasing a compatibility update, run automated tests, verify the actual affected game branch, exercise PCL library/Forge/preview workflows on copied saves, update evidence/status, and package a new framework build. Keep exact game build, profile, framework, API, manifest-schema and mod versions independent.


## Executable patch packs

`compat/patches.lua` selects a framework-owned JSON file in `compat/builds/` by the full executable SHA256. A known Steam branch with an unfamiliar hash does not inherit another build's native code. A conflicting branch/hash combination remains unknown.

Packs contain `schema_version`, `id`, `branch`, `buildid`, `sha256`, `status`, mapping `overrides`, per-helper `native_helpers`, and per-mod `mod_data`. Mapping categories are objects, classes, functions, events and capabilities. The framework applies these mappings in every client Lua state, including after asynchronous build identification. These are data files, not arbitrary Lua patch scripts or instructions to modify the game executable.

```lua
Framework.Ready(function()
    local selected = Framework.GetCompatibilityData()
    local data = Framework.GetCompatibilityData('ExampleMod')
    local helper, reason = Framework.GetNativeHelper('example.dll')
    -- Use reflected APIs when helper is nil; display reason when the feature needs native code.
end)
```

A replacement helper may use a pack entry such as `{"verified":true,"path":"native/bleedingedge/example.dll"}`. The DLL must ship inside the framework and must be separately ABI-validated. Paths cannot escape the framework. Unverified entries return their reason, with no fallback to Main. Native DLLs keep their own runtime guards.

Main 25431485 retains its existing legacy PCL helper approval. Bleeding Edge 25940006 is identified and selects its own pack, but its PCL import/cache/blade helpers are blocked. The read-only native audit found 0/17 recorded import-hook guards, 1/12 cache guards, and 1/15 blade guards matching their Main addresses. These results establish incompatibility of the fixed addresses, not replacement addresses. PCL must use the framework-dependent migration to receive this gate; an older standalone PCL installation still uses its own guards.

Run `Tools/audit_native_guards.py` for a reproducible read-only PE guard report. This audit never enables native code. A fresh Bleeding Edge dump was captured on 2026-10-29 and compared with the preserved original Main headers. ASwordPartActor now derives from ASwordActorBase; material/polish moved into that base. FSwordPartData.bHasPrimarySlot moved from 0xD9 to 0xDB. Exact per-build reflected layouts are available in GetCompatibilityData("PreconstructionLibraryProbe").reflected_layouts. Missing Blueprint classes in a dump may reflect unloaded assets, so the raw added/removed class counts do not prove game removals.
