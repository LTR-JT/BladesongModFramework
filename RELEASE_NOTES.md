Bladesong Mod Framework 0.1.7

Download **BladesongModFramework_0.1.7_Easy_Install_With_UE4SS.zip** for a new installation. Close Bladesong, Extract All, open the folder and double-click INSTALL.cmd. UE4SS is included and its debug windows are disabled.

- Fixed one-click installation after a previous completed transaction. New and legacy pending plans receive valid transaction IDs before the game exits.
- Shorter backup paths avoid Windows path-length failures during updates.
- The helper records the installation result and relaunches Bladesong after applying changes, including an ordinary failed apply. Failed changes are reported on the next launch.
- Check for updates shows Checking on each installed mod, then Up to date, Update, or a clear failure/unavailable status. Checks run concurrently in the background.
- Installed mod cards include Uninstall. The game exits normally, the mod is removed from the load order, and its complete folder is kept under Bladesong/Binaries/Win64/BMF_Uninstalled. Libraries and other mod data are preserved. Enabled dependents must be removed or disabled first.

PCL 15.18.2 remains compatible. All changes retain the existing Creative menu, catalogue cache and background refresh improvements.
