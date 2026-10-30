# Troubleshooting and diagnostics

If Mods does not appear, check UE4SS.log for BMF initialization and the native main-menu attachment message. Verify the framework and shared module folders are siblings under Mods, and enabled.txt exists. The local UE4SS default UObject-array cache was already disabled for the known startup issue; this framework does not alter those settings.

If a mod says the framework is missing, check its API requirement and installation path. Dependent Lua states do not share ordinary globals. Readiness is separate from registration and capability availability.

If an unknown build is detected, retain the diagnostic report and new reflection dump. Do not force native helpers onto an unverified executable. Main/Bleeding Edge labels are evidence-based and may remain unknown.

If a download fails, inspect the source URL, release asset name, archive manifest, declared hashes and dependency requirements. Nexus HTML pages are not archives. The worker does not bypass certificate validation, Windows security, anti-malware controls, or PowerShell policy. The shipping worker is compiled .NET and does not require PowerShell script execution.

If an update refuses local edits, preserve those edits and compare the managed file record. Do not delete save folders to force an installation. A failed staged operation keeps its journal/backups under the framework Data directory.

Developer reports should include framework/API version, game build, active profile, capability failures and the relevant error. Avoid including full save files, account IDs, hardware identifiers or unrelated system logs. F.ExportDiagnostics is a local file export; uploading it is a separate player action.
