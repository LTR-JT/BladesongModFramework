# Preserving old mods

Historical v1 source and its public contract are frozen under `Tests/frozen/` and `SDK/contracts/v1.0.0.json`. Tests verify fixture hashes before running. Add regressions for abandoned SDK consumers rather than editing their code until a test passes.

Existing `api.lua` imports remain supported. New code can load `sdk.lua` with `root, '=1.0.0', optional_mod_id` for the historical facade. Retained functions continue forwarding into current services. Unsupported API generations report an explicit error; SDK 2/3/5 do not exist merely because preservation of such generations is a design objective. Tests simulate an internal version advance while keeping the v1 facade.

The public service contract, historical facade, game adapter, raw UE4SS backend and menu/worker services are separate boundaries. A future official backend could replace services without editing mod consumers; no official backend or cooperation is assumed.

Framework-owned patch packs may provide bounded `operations` recipes. A recipe resolves known object aliases, obtains a service, calls a method with converted/reordered/constant arguments, reads properties, constructs a legacy record, and extracts a wrapped result. Limits are 32 operations and 16 call arguments. Recipes are trusted framework maintenance data, not downloadable mod scripts. Errors stop the operation; a missing object is not replaced by a guessed pointer. Equivalent multi-step initialization/construction paths can be supplied when their behavior is verified.

Property aliases and event adapters preserve legacy names/shapes independently from hook-target aliases. Default live implementations use observed Forge/Piece interfaces. Synthetic future interface recipes are test fixtures, not speculative patches deployed into real game builds.

`GetSwordSnapshot` returns detached `{schema_version=1, kind='sword', name=string, part_count=integer}` data. `SynchronizeSword` encapsulates the current native actor-to-design synchronization sequence. Existing `GetCurrentSword`, `GetSwordDesign`, `ResolveObject`, `ResolveClass`, and component APIs remain advanced transient-object escape hatches. They cannot promise permanence of native UObject ownership across world changes. Validate and reacquire objects; never persist their addresses.

Compatibility states distinguish `framework-ready` (requirements available, behavior not automatically certified), `requires-framework-work`, ordinary `raw-interfaces-unknown`, invalid manifests, and explicit raw build mismatches. API age alone is not incompatibility. Loading files is not behavioral validation.

Legacy settings still use the existing JSON per-mod layout. No player library format, game save or third-party binary is automatically rewritten. For a genuinely unavoidable contract break, retain a safe old facade if possible, publish the reason and migration instructions, add a reproducing frozen regression, and record the precise loss of functionality.
