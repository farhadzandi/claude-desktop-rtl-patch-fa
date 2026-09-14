# Attribution and derivative-work notice

## Original project

This repository is based on:

- **Project:** Claude Desktop RTL Patch
- **Upstream:** https://github.com/shraga100/claude-desktop-rtl-patch
- **Original author / copyright holder:** shraga100
- **License:** MIT License
- **Original focus:** Hebrew and Arabic RTL support for Claude Desktop on Windows

The upstream copyright notice and MIT permission notice are preserved in `LICENSE`.

## Persian secure customization

This derivative focuses on:

- Persian-first RTL behavior and Persian test coverage.
- Removal of legacy Hebrew user-facing strings from the Persian distribution.
- Exact-scope temporary WindowsApps access with ACL/owner snapshot, restoration, and verification.
- Protected backups outside the WindowsApps application tree.
- No scheduled auto-repatch or background watcher.
- No remote self-updater in the hardened build.
- Refusal to disable Electron integrity fuses as a generic fallback.
- Transparent local certificate identity.
- Verified destruction of the temporary signing private key.
- No RSA-1024 signing fallback.
- Security audit, package verification, cleanup, ACL repair, and post-install verification tools.

## No affiliation

This derivative is not an official Anthropic project and is not endorsed by Anthropic.

## Credit policy

Please preserve the upstream MIT license and this attribution notice in redistributed copies or
substantial derivatives.
