# Bladesong Mod Framework

Manager-independent compatibility runtime and shared game UI for Bladesong. This source candidate is runtime 0.1.8 on stable API 1.0.0. It contains no in-game manager, downloader or installer.

The separate [BladesongModManager](https://github.com/LTR-JT/BladesongModManager) supplies optional installation and update management. The separate [BladesongSDK](https://github.com/LTR-JT/BladesongSDK) supplies schemas, templates, documentation and packaging tools. [PreconstructionLibrary](https://github.com/LTR-JT/PreconstructionLibrary) depends only on this runtime.

Players with UE4SS can install the framework Runtime ZIP manually and enable BladesongModFramework before dependent mods. No manager application needs to be installed or running. For first-time setup with the optional manager and UE4SS, use that repository's bootstrap instructions.

## Development

Clone BladesongSDK beside this checkout, or set BMF_SDK_ROOT to its path. It is a build-time tools dependency only. No manager source is needed. The reviewed SDK revision is recorded in BuildDependencies.json.

```powershell
python Tools/run_checks.py --lua C:/path/to/lua.exe
python Tools/build_native.py --build 25940006
python Tools/build_native.py --build 25431485
python Tools/run_native_tests.py
python Tools/package_release.py
python Tools/check_packages.py
```

Contracts/ contains the runtime's API snapshots and Tests/frozen contains preserved consumers. SDK owns the portable schemas and developer tools. Shared Creative/Story/PCL-provider UI stays here.

The current source split is not a new released or live-game-certified build. Release workflows require explicit manual dispatch; source pushes do not publish releases. Exact-build native gates remain in place. Original code and assets are MIT licensed; see LICENSE and THIRD_PARTY_NOTICES.md.
