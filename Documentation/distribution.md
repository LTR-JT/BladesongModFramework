# Manifests, installation and updates

The schema is SDK/bmf-manifest.schema.json. A BMF ZIP contains a root bmf-manifest.json and only files declared by path, expanded byte size and SHA256. Paths are relative to the mod directory whose name matches its ID. The framework alone may install its own shared module subtree. Ordinary mod manifests cannot write arbitrary game directories.

Tools/package_mod.py produces the archive and hashes. A bmf-release.json is that manifest plus download.url and download.sha256 referring to the whole archive. Put exactly one such asset on a public GitHub release. Repository, tagged-release, release-asset and HTTPS archive/manifest URLs have distinct resolution paths. No example points at an invented public repository.

Players inspect publisher/source metadata, then approve download/staging. Stage re-fetches the source and checks the reviewed manifest digest, identity and version. Missing or incompatible dependencies block staging; this version validates installed dependencies but does not recursively fetch them from undeclared sources.

Archive limits are 64 MiB downloaded, 256 MiB expanded, 4096 declared files, 64 MiB per file and bounded JSON. Traversal, absolute paths, alternate streams, reserved Windows names, symlinks, reparse-point destinations, case duplicates, unlisted files and save/library paths are rejected. Bundled installation scripts are never run. A matching hash is integrity evidence, not publisher trust. Unsupported signature types are rejected rather than presented as verified.

The updater waits for all game processes from the exact installation to exit. It stages backups and journals before writes, verifies installed hashes, and rolls back ordinary apply failures. It refuses to overwrite unmanaged files or changed managed files. Interrupted-process recovery still requires validation and should not be advertised as crash-proof; keep rollback backups for manual recovery.

Automatic checks run hourly when enabled. Stable GitHub releases are the default; the worker can resolve prerelease channels and honors pinned_version in installed release metadata. Installing remains a review/approval operation. Automatic trusted-source installs and recursive dependency downloads are not enabled in this preview.

The helper is UI-free and does not terminate the game. Restart & Apply warns about unsaved gameplay, saves framework settings, starts a copy of the worker for the approved plan and requests a normal game quit. The copied helper permits replacement of the installed worker itself after shutdown. No administrator elevation or persistent service is used.
