# First mod

Copy SDK/templates/basic into a new Mods/ExampleHello directory, preserving Scripts/main.lua and enabled.txt. Use the supplied LuaLS definitions for autocomplete. Python 3.10+ is used only for SDK generation/tests/packaging. Windows .NET Framework's compiler builds the bundled worker; no compiler is needed to play.

The example loads the shared API into its own Lua environment, waits for framework readiness, registers serializable metadata and retains its callback locally. It does not assume independent UE4SS mods share a Lua state.

Run Python Tools/package_mod.py against your mod folder to create a hashed BMF archive. Keep personal data outside package inputs. Supply your real repository URL in your manifest before publishing; example templates deliberately have no fabricated repository or author identity.

Run the examples first with a mock game, then in your own backed-up development save. A successful Lua syntax check is not in-game behavioral validation. Use compatibility APIs instead of embedding game paths or native offsets in a new mod.
