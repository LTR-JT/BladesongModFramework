# Player installation

Install a compatible UE4SS runtime first. The tested local installation reports UE4SS 3.0.1 Beta #0, commit a1e7f571, Engine 5.7. Debug console/GUI preferences are not enabled by this framework.

Close Bladesong normally. Extract the Framework package into the outer Bladesong installation folder beside Bladesong.exe. The resulting folders must include Bladesong/Binaries/Win64/ue4ss/Mods/BladesongModFramework and Mods/shared/BladesongFramework. Keep their relative locations intact.

Launch the game normally and use Mods on the existing main menu. There is no external mod-management UI. The .NET worker has no UI and performs only framework-requested background download/staging and approved shutdown-time file operations. Windows .NET Framework 4.x is required; Python and PowerShell are not player dependencies.

PCL is distributed separately at https://github.com/LTR-JT/PreconstructionLibrary. Preserve your existing preconstructions, blades, settings and game saves; never remove those folders while upgrading. The baseline 15.17.62 packages remain available. Do not mix a migrated PCL loader with an older framework API.

Disabling a mod is queued for the next launch. It does not unload its hooks, native DLLs or spawned objects in the current process. Loaded binary updates apply only after normal game exit. Framework disabling is blocked while acting as the required runtime.

The in-game installer accepts the BMF manifest/archive format, not an arbitrary ZIP made for manual drag-and-drop installation. A normal GitHub release needs a mod.json asset with its archive URL and hash. Nexus webpages are not treated as downloads.
