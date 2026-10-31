# Independent releases

Runtime, optional manager, SDK and PCL each have their own repository, version and v-tags. This repository publishes only framework Runtime/Package archives and mod.json. Building or pushing source does not authorize a release.

Run this repository's checks, native fixtures and package checks first. The SDK build-tool revision is recorded in BuildDependencies.json. After explicit release authorization, dispatch publish.yml with a matching v-tag; draft is the default. No push-triggered release workflow remains. The legacy release plan is publish=false.

Manager bootstrap assembly and configured UE4SS packaging live in LTR-JT/BladesongModManager. Developer SDK releases live in LTR-JT/BladesongSDK. Neither needs its version bumped for an ordinary compatible framework update. Preserve the API 1 contract snapshots and frozen consumer fixtures.
