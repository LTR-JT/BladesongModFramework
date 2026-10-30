> Publication update (2026-10-29): original project code/assets are now MIT licensed by the owner. The two public repositories are LTR-JT/BladesongModFramework and LTR-JT/PreconstructionLibrary. Historical audit notes below describe the earlier workspace.

# Dependencies and provenance

| Component | Use | Distribution status |
| --- | --- | --- |
| UE4SS | Player runtime, reflection, hooks, SDK dump tooling | Separately installed dependency; exact upstream redistribution terms require release review |
| Windows .NET Framework | Headless worker and standard JSON/ZIP/HTTP APIs | Uses OS runtime; no downloaded runtime bundled |
| Lua 5.4 executable | Developer fixture runner | Local tooling; CI downloads a pinned checksum-verified source archive and builds it |
| Python | Developer build/tests/docs | Not required by players |
| PCL source/helpers/menu assets | Existing project migration and native UI | Preserve provenance and ownership; do not assume their authorization covers stock game assets |
| Bladesong/Unreal | Runtime interfaces discovered locally | No game executable, raw dump tree or proprietary game asset in public source/release bundles |

No project license has been assigned. Publication needs an owner-approved license and reviewed third-party notices. Local Compatibility evidence and SDK/game-reference.json contain generated game interface material and are excluded from public packaging pending provenance review.
