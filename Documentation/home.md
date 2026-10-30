# Bladesong Modding Platform

This is the 0.1.0 implementation preview: a UE4SS framework, an in-game Mod Manager, a separate developer SDK, and a PCL migration candidate. It is not a standalone launcher.

Use the status report in the release directory before distributing a build. Public/Main Steam build 25431485 is the locally identified game. Bleeding Edge has not been independently exercised. An exact executable match permits PCL's existing guarded native helpers; it does not prove every game behavior is compatible.

- [Player installation](installation.md)
- [First mod](first-mod.md)
- [Framework API](framework-api.md)
- [Game reference](game-reference.md)
- [Compatibility maintenance](compatibility.md)
- [Distribution and updates](distribution.md)
- [Troubleshooting](troubleshooting.md)

The reusable PCL native-grid host, folder lips, hover/hit-area logic, and registry were moved into framework-owned modules. PCL's construction, cache, library and Forge algorithms remain PCL-owned. See Migration/dependency-audit.json for the remaining direct game lookups; this preview does not claim to have abstracted every legacy call.
