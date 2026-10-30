# Bladesong Mod Framework

A community framework, in-game Mods menu and developer SDK for Bladesong.
It keeps game compatibility adapters in one place so mods can use a stable API.

**Community preview.** The current PCL adapter has been exercised on Main and
Bleeding Edge locally. Unknown executables remain blocked for native operations;
future game updates still require compatibility work.

## For players

1. Close Bladesong.
2. Download **BladesongModFramework_0.1.6_Easy_Install_With_UE4SS.zip** from [Releases](https://github.com/LTR-JT/BladesongModFramework/releases/latest).
3. Right-click the ZIP and choose **Extract All**.
4. Open the extracted folder and double-click **INSTALL.cmd**.
5. Press **Enter** to install, then start the game.

Click **Mods**, just above **Options**, on the main menu.
UE4SS is included. You do not need to install it separately.

If the installer asks for the game folder, open Steam, right-click Bladesong,
then choose **Manage > Browse local files**. Select that folder in the installer.

Browse loads the community mod list automatically. Each mod is reviewed before
installation. Your saves, PCL library and other mods are not deleted. Replaced
files are backed up in **BMF_Backups** inside the game folder.

### Copy files manually instead

Copy the extracted **Bladesong** folder into the game folder opened by Steam.
Choose **Replace** when asked. Keep existing saves and the Mods folder.

The small Runtime ZIP is for people who already have compatible UE4SS.
The BMF ZIP is for the in-game updater. GitHub's Source code ZIP is for developers.

## For mod authors

- Start with [your first mod](Documentation/first-mod.md) and the SDK templates.
- Use `mod.json` for API requirements, dependencies and capabilities.
- Keep repository metadata in your own repository; release metadata is authoritative.
- Submit a name and repository URL to `mod-index.json` for optional discovery.
- Keep game-specific raw integrations in the framework's build-specific adapters.

The API 1.0.0 contract and frozen compatibility fixtures are preserved. The SDK
does not promise that arbitrary native binaries work on unknown game builds.

## Development

Windows, Python 3.12+, Lua 5.4, Visual Studio C++ build tools and Windows .NET
Framework 4.x are used for development. Players do not need those build tools.

```powershell
python Tools/run_checks.py --lua C:/path/to/lua.exe
python Tools/build_native.py --build 25940006
python Tools/package_release.py
```

CI builds a pinned Lua runner, runs preservation/worker fixtures, compiles the
native adapters, and prepares installation artifacts. Release publication is a
manual workflow that creates a draft. Native-source changes need live tests on
the exact corresponding game executable before release.

## License

Original code and project assets are MIT licensed. See [LICENSE](LICENSE) and
[third-party notices](THIRD_PARTY_NOTICES.md). This is an independent community
project, not an official Bladesong or UE4SS release.
