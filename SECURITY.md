# Security reporting

Do not publish exploit details, tokens, player saves or unredacted logs in public issues. A private reporting address/channel has not been configured; the maintainer must configure GitHub private vulnerability reporting or a private contact before public release. Do not invent a contact or promise response times.

Report affected framework/worker versions, a minimal synthetic reproduction, expected versus observed behavior, and impact. Use sanitized fixtures. Treat repository manifests and archives as untrusted. Hashes provide integrity, not publisher trust. Network work must stay outside the game thread; installers must validate paths, hashes, links, bounds and explicit approval, then apply after normal exit with rollback.

Never automatically alter third-party mod code/binaries to preserve compatibility. Unsupported integrations should fail accurately and retain user data. Native changes require exact-build ABI evidence and regression tests.
