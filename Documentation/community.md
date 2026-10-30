# Community maintenance

Preserve APIs and working features before replacing them. Prefer central compatibility repairs to demands that every mod author update. Keep changes small enough to review, use stable SDK names and detached data where possible, and keep native escape hatches explicit.

Before changing an adapter, preserve the exact build identity and reflected evidence privately, reproduce the failure, run unchanged frozen consumers, and test the affected behavior in-game on copied development saves. Mark simulations separately from live checks. A changed dump or matching byte guard alone cannot certify gameplay.

New API generations require a parallel historical facade and tests for old parameter/return/error behavior. Deprecation means documentation and forwarding, not automatic deletion. Frozen-source hash changes require a separately explained contract decision; never silently regenerate hashes to fix a regression.

Registry submissions change only a mod's name and repository URL. Versions, descriptions, dependencies, manifests and releases remain in the author's repository. Unlisted mods have equal SDK access. No registration website or central approval is required.

PR validation checks the index, manifests, historical source hashes, API drift, portable Lua services, worker fixtures and package hygiene. Windows CI builds the worker and runs all fixtures. Documentation builds produce artifacts only; publication requires an authorized release and provenance/license review.

Use plain names, explicit errors, bounded iteration/IO, no speculative reflection, no pointer persistence, no hidden writes to user saves, and no game-thread network work. Keep public SDK, historical adapters, game backend, services, UI and distribution independently understandable. Report unavoidable raw/native/cooked-asset incompatibilities accurately. Official adoption is welcome as a possibility, not an endorsement or dependency.
