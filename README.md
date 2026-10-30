# Bladesong Mod Framework

A community framework, in-game Mods menu and developer SDK for Bladesong.
It keeps game compatibility adapters in one place so mods can use a stable API.

**Community preview.** The current PCL adapter has been exercised on Main and
Bleeding Edge locally. Unknown executables remain blocked for native operations;
future game updates still require compatibility work.

## For players

Install a compatible [UE4SS runtime](https://github.com/UE4SS-RE/RE-UE4SS) first.
Close the game, then extract the framework **runtime ZIP from Releases** into the
outer Bladesong game folder, beside `Bladesong.exe`. Do not use GitHub's automatic
Source code ZIP as an installer. The archive includes the project's shared menu
asset pack; the game executable and UE4SS are separate dependencies.

The main menu gains a **Mods** button above Options. Mod enabling/disabling takes
effect on the next launch. Install/update operations require review and normal
game exit; the framework does not kill the game. Debug windows remain off unless
enabled in UE4SS settings.

See [installation](Documentation/installation.md),
[troubleshooting](Documentation/troubleshooting.md), and the
[Preconstruction Library](https://github.com/LTR-JT/PreconstructionLibrary).

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
