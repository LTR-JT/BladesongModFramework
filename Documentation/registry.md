# Decentralized discovery

The central `mod-index.json` accepts exactly `mods`, containing entries with exactly `name` and `url`. Add a name and public GitHub repository URL through a pull request. Index inclusion is not approval of publisher code and is not required for installation or SDK use.

Each repository supplies `mod.json` at its default branch. The browser obtains it using GitHub's [repository contents endpoint](https://docs.github.com/en/rest/repos/contents). Repository metadata is for browsing. Reviewing an install resolves a particular release's `mod.json` asset, whose version, file hashes and download metadata are authoritative. The legacy release asset `bmf-release.json` and archive `bmf-manifest.json` remain readable.

The existing in-game Mods page adds Browse. Enter the HTTPS URL of the published central JSON index, refresh, and review an author's release before approving installation. The index is initially empty and no public URL is invented or published by tooling. Manual repository/release/HTTPS URL installation stays available.

All network work runs in the worker. Registry browsing is bounded to 64 repositories, four concurrent metadata requests, eight-second request timeouts and a 45-second batch deadline plus outstanding request completion. Repository metadata is cached for one hour, with stale fallback when a repository or index fails. One unavailable repository does not suppress others. Explicit offline operation uses cached metadata. GitHub [rate-limit headers](https://docs.github.com/en/rest/using-the-rest-api/troubleshooting-the-rest-api) create a persisted provider cooldown; the worker does not retry through it.

Public end-to-end registry behavior is not certified until a real configured registry and mod release are exercised. Current automated coverage validates index shape/URLs, capability-based compatibility, metadata ownership, offline cache fallback and per-repository failure isolation without depending on external network availability.
