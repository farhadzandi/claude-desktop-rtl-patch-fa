# Release notes — v1.3.2

First public-release candidate of the Persian security-hardened Claude Desktop RTL patch.

## Highlights

- Persian-first RTL behavior with 56 automated Node tests.
- Exact-scope temporary WindowsApps ACL access with snapshot, restoration, and verification.
- Secure backups outside the application tree.
- No scheduled auto-repatch, background watcher, or remote updater.
- No Electron integrity-fuse disable fallback.
- RSA-1024 fallback removed; RSA-2048 / ECDSA P-256 only.
- Temporary signing private key must be verifiably destroyed.
- Package SHA-256 manifest and fixed package verifier.
- Built-in Security & Maintenance menu:
  - package verification
  - read-only security audit
  - current security-state verification
  - legacy ACL repair (dry-run/apply)
  - legacy residue cleanup (dry-run/apply)
- Full Persian and English installation/troubleshooting documentation.
- Explicit attribution to the upstream `shraga100/claude-desktop-rtl-patch` MIT project.

## Codex / ChatGPT Desktop

Not supported in this release. Support is intentionally deferred until a separate target-specific
integrity and rollback adapter is verified.

## Recommended install sequence

```powershell
powershell -ExecutionPolicy Bypass -File .\Verify-Package.ps1
.\run-patch.bat
```

Choose Install/Re-Apply, then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\Verify-Security-State.ps1 -ExportReport
```
