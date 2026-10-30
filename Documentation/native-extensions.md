# Native extensions and lifetime safety

The framework worker uses C# and Windows .NET Framework APIs for HTTPS, bounded ZIP extraction and post-exit transactions. It is built from UpdaterHelper/Worker.cs by Tools/build_worker.py. It has no mod browsing/configuration UI and does not inject into Bladesong.

PCL's existing C++ helpers are preserved byte-for-byte in the migration package. Their BridgeSource is included in the SDK maintenance reference. They are not universal UE5.7 libraries: the game executable, native call sites, UObject layouts, Lua ABI and prologue bytes must all be verified before rebuilding or permitting a new build.

Never retain raw UObject pointers across garbage collection or level transitions without valid ownership. A Lua proxy existing is not proof of native lifetime. Do not call engine functions from a filesystem/download thread. Do not transfer Lua callbacks between independent mod states. Profile adapters must fail closed when a required signature or capability is unavailable.

The native-diagnostics example is a standalone developer utility that prints its own process architecture. It is not a player launcher, a DLL-injection template, or a fabricated UE4SS ABI binding. Developing an in-process C++ mod requires a matching UE4SS C++ SDK/toolchain and a separately verified ABI.
