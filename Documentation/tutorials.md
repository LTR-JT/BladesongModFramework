# Tutorials

Each named Lua example is an actual loadable SDK template. A mock test is not runtime verification on either game branch.

## 1. Hello World

Start with SDK/templates/basic.

Read Scripts/main.lua, choose a unique ID, install into its matching mod folder, and validate the intended behavior on a copied development save. See the API reference for return values and errors.

## 2. Mod registration

Start with SDK/templates/basic.

Read Scripts/main.lua, choose a unique ID, install into its matching mod folder, and validate the intended behavior on a copied development save. See the API reference for return values and errors.

## 3. Mod Manager page

Start with SDK/templates/menu-page.

Read Scripts/main.lua, choose a unique ID, install into its matching mod folder, and validate the intended behavior on a copied development save. See the API reference for return values and errors.

## 4. Custom UI

Start with SDK/templates/menu-page.

Register a local page callback first. Reuse framework UI modules with a host adapter; do not pass UMG objects or Lua functions through cross-mod metadata. The preserved PCL host is the concrete complex-menu example.

## 5. Input handling

Start with SDK/templates/sword-reader.

Read Scripts/main.lua, choose a unique ID, install into its matching mod folder, and validate the intended behavior on a copied development save. See the API reference for return values and errors.

## 6. Reading sword data

Start with SDK/templates/sword-reader.

Read Scripts/main.lua, choose a unique ID, install into its matching mod folder, and validate the intended behavior on a copied development save. See the API reference for return values and errors.

## 7. Component presentation transforms

Start with SDK/templates/component-transform.

The template exports ExampleSetPresentationTransform(component,transform). Call it with a valid current SceneComponent and a complete FTransform-compatible table. It changes presentation only and does not commit serialized sword construction.

## 8. Events and hooks

Start with SDK/templates/events.

Read Scripts/main.lua, choose a unique ID, install into its matching mod folder, and validate the intended behavior on a copied development save. See the API reference for return values and errors.

## 9. Saving custom data

Start with SDK/templates/persistent-data.

Read Scripts/main.lua, choose a unique ID, install into its matching mod folder, and validate the intended behavior on a copied development save. See the API reference for return values and errors.

## 10. Compatibility APIs

Start with SDK/templates/compatibility-aware.

Keep mapping changes inside the framework. Check capabilities rather than branching on engine version. Tests/core.lua demonstrates unchanged dependent code after a mapped getter changes. Bleeding Edge remains unverified until its actual build is tested.

## 11. Both game branches

Start with SDK/templates/compatibility-aware.

Keep mapping changes inside the framework. Check capabilities rather than branching on engine version. Tests/core.lua demonstrates unchanged dependent code after a mapped getter changes. Bleeding Edge remains unverified until its actual build is tested.

## 12. Debugging UE4SS errors

Start with SDK/templates/configuration.

Read Scripts/main.lua, choose a unique ID, install into its matching mod folder, and validate the intended behavior on a copied development save. See the API reference for return values and errors.

## 13. Native integration

Start with SDK/templates/native-diagnostics.

Build with CMake and run the diagnostic executable locally. It reports pointer size; it does not provide an unverified injected UE4SS C++ API.

## 14. Packaging a release

Start with SDK/templates/basic.

Run python Tools/package_mod.py <mod-directory> <archive.zip>. Inspect the archive manifest and run installation fixtures before publishing.

## 15. GitHub updates

Start with SDK/templates/basic.

Add your actual public repository and channel to the manifest. Publish bmf-release.json with download.url and the archive SHA256. Use an authorized GitHub release process; no release is published automatically by local packaging.
