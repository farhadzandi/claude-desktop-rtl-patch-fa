# Security Policy — v1.3.2

## Read this before installation

This patch performs privileged, security-sensitive modifications because Claude Desktop validates its
packaged Electron application and helper binaries. The hardened design tries to minimize, snapshot,
verify, and roll back those operations. It does **not** make binary patching risk-free.

## Expected while Claude is patched

- Modified `app.asar`, `claude.exe`, and `cowork-svc.exe`.
- A public-only self-signed certificate in `LocalMachine\Root` with subject:
  `CN=Claude RTL Local Patch, O=Local User Patch, C=US`.
- Vendor backups under `%ProgramData%\ClaudeRtlPatch\backups\<version>`.
- `patch.log`, state, and optional custom-font configuration under `%ProgramData%\ClaudeRtlPatch`.

## Not expected

- A private signing key remaining in `LocalMachine\My`.
- Any RTL-patch Scheduled Task.
- Any background watcher/updater from this build.
- Recursive ownership changes across the Claude WindowsApps tree.
- Explicit `Administrators:FullControl` residue on patch targets after the operation.
- Adjacent `.bak` files inside WindowsApps.
- Electron ASAR-integrity fuse being disabled.

## ACL model

The patch snapshots exact owner/access state of the small set of required targets, obtains temporary
access only for those targets, removes its explicit temporary grant, restores original owners, then
compares the resulting owner/access SDDL against the snapshot.

If restoration cannot be verified, the operation is not reported as clean.

## Certificate/key model

The build tries RSA-2048 first and ECDSA P-256 (`nistP256`) if a smaller certificate is required by
Claude's fixed certificate slot. RSA-1024 is intentionally refused.

The temporary signing private key must be deleted and verified absent. If key destruction cannot be
confirmed, installation fails/rolls back.

## Runtime external dependency

`@electron/asar@4.2.0` is version-pinned and invoked through `npx`. First use may still depend on the
npm registry/network supply chain. This is the principal remaining external runtime dependency and a
future hardening target.

## No persistence/update mechanism

v1.3.2 does not install:

- Scheduled auto-repatch tasks
- Background watchers
- Remote patch self-updaters
- Quick-update persistence

After a Claude Desktop update, re-apply manually.

## Package verification

Run before installation:

```powershell
powershell -ExecutionPolicy Bypass -File .\Verify-Package.ps1
```

Run after installation:

```powershell
powershell -ExecutionPolicy Bypass -File .\Verify-Security-State.ps1 -ExportReport
```

## Reporting a security issue

For a public repository, do not post credentials, internal corporate paths, conversation data, or
private logs in a public issue. Prefer a private GitHub Security Advisory once the repository is live.
