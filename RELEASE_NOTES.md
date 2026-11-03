Bladesong Mod Framework 0.1.11 candidate

The Framework now identifies the game build, saves settings, and enumerates save files through an in-process Windows DLL. File operations run off the game thread, and native compatibility selection still requires the executable's SHA-256 fingerprint.

The runtime package drops bmf-worker.exe and bmf-launch.dll. The Mod Manager is distributed separately.
