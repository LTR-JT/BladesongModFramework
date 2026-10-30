# Preservation implementation report — 0.1.2 preview

Date: 2026-10-29. This supplements the pre-change audit; it does not replace historical live evidence with simulated results.

| Requirement | Implemented | Evidence / limit |
| --- | --- | --- |
| Preserve existing SDK | Frozen 29-function v1 contract and explicit historical facade; existing imports retained | Hash/signature checks; unchanged frozen mod passes after simulated internal version advance; only generation 1 exists today |
| Behavioral translation | Internal service/backend boundary; bounded operation recipes for multi-step object resolution, calls, argument conversion, property reads, legacy records and wrapped results | Synthetic subsystem/ownership/parameter/return changes pass without editing the frozen mod |
| Event/hook changes | Hook targets remain mapped; framework converts contexts and event argument shapes | Synthetic legacy event signature fixture passes |
| Normalized data | Additive detached sword snapshot plus stable actor/design synchronization service | Scalar-only snapshot and invalid-lifetime fixtures; actual UE4SS TArray/name conversion not separately live-certified in this revision |
| Central build support | Exact executable JSON patch packs and helper gating retained | Main 25431485 / Bleeding Edge 25940006 identified; earlier live menu and BE profile-selection evidence preserved |
| Branch-free mod manifests | Normal manifests target APIs/dependencies/capabilities; deprecated top-level build lists no longer gate SDK compatibility | Worker tests cover capability readiness and narrowly scoped explicit raw exceptions |
| Simple registry | Index contains only name and repository URL; repository `mod.json` owns metadata; release manifest authoritative for installation | Offline index/cache/failure tests; no real public registry URL configured, no end-to-end hosted catalogue test |
| Async discovery | Worker uses max four metadata requests, 64 repositories, timeouts, deadline, one-hour cache/stale fallback and rate cooldown | Installer/worker tests exercise offline paths; live provider throttling not induced |
| Installed mods | Ordinary, manifest, invalid-manifest and SDK integration distinguished; metadata-only discovery needs no registration | Discovery fixtures pass; interactive examples use manifest binding |
| PCL | Generated migration uses framework synchronization/current/design services and manifest binding; shared UI preserved | Nine native DLLs byte-identical, baseline source unchanged, legacy menu/input fixtures pass; full migrated PCL gameplay remains unverified |
| Legacy data | Existing settings JSON remains readable; no library/save rewrite | Frozen settings fixture and existing backup/deletion guards pass |
| Community readiness | README, layered architecture, contribution/security/provenance/license guidance, index and API checks, Windows CI workflow | No license selected, repository created, release published, or official endorsement assumed; CI workflow prepared but not run on a hosted runner |

## Validation performed locally

`Tools/run_checks.py` runs repository/frozen/hash checks, API generation, searchable docs generation, all runtime/template/generated-runtime Lua syntax, six Lua fixture suites, worker identity fixtures, eleven installer/discovery/cache fixtures, local PCL migration byte-preservation checks, and existing PCL menu/input regressions. Successful local results are required before packaging.

The frozen fixture executes unchanged across simulated interfaces for Main and Bleeding Edge. A second scenario reorganizes object ownership/subsystems, adds and reorders arguments, wraps the sword return, reshapes design data and changes event arguments. Only framework-owned adapters change. A provider replacement demonstrates the internal backend boundary. These are simulations, not claims that those hypothetical changes have shipped in Bladesong.

## Known limits and unfinished runtime work

Bleeding Edge native PCL import/cache/blade helpers remain incompatible and blocked in the framework-dependent path. Native ABI/cooked-asset exceptions cannot be repaired by renaming methods. The installed standalone PCL baseline retains its own guards until an independently validated migration replaces it. Not every legacy PCL direct game access is yet abstracted.

Main and Bleeding Edge reflected interface snapshots exist locally, but missing classes in a dump can reflect unloaded assets. Unknown executable hashes receive capability probes and no unverified native fallback. No unobserved future build is certified.

The browser requires a configured HTTPS index URL. No publisher authenticity/signature system, public submission service or automatic third-party code modification is implied. Interrupted updater-process recovery and full live self-update/PCL workflows remain separate release-readiness work from the preservation additions.

The runtime still uses PCL's existing shared menu asset; the public update package assumes that asset and UE4SS are already installed. Public source/SDK bundles exclude raw game dump trees, game executables, proprietary cooked assets and generated game-reference.json pending provenance review. These omissions are deliberate publication limits, not a claim of a complete standalone fresh-install release.
