# Troubleshooting

## `node` / `npx` not found

Check:

```powershell
node --version
npx --version
```

Install a current Node.js release and reopen the terminal.

## Node is too old

Minimum supported version is `22.12.0`.

## Claude installation not found

Install Claude Desktop and launch it once. Repair/reinstall the official app if AppX registration is broken.

## Dirty ACL baseline / ACL modification evidence

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-Audit.ps1 -ExportReport
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-ACL-Repair.ps1
```

Review dry-run output before applying `-Apply`.

## Package hash mismatch

Do not run the patch. Re-download the trusted release and fully extract it.

## ASAR extract/pack failure

Check Node, `npx`, first-run network access, and:

```text
%ProgramData%\ClaudeRtlPatch\patch.log
```

## Certificate/signing failure

The secure build accepts RSA-2048 and ECDSA P-256 only. RSA-1024 is intentionally refused. A signing
or fixed-slot compatibility failure should abort/roll back rather than weaken the configuration.

## ACL restoration could not be verified

Do not leave the system in that state. Restore, audit, and use the legacy ACL repair tool. If required,
reinstall official Claude Desktop.

## Claude does not start after patching

Restore original files, verify the security state, then reinstall official Claude if a valid backup is
not available.

## RTL disappeared after a Claude update

Expected. Auto-repatch is intentionally disabled; manually re-apply the patch.

## PowerShell 7

Use Windows PowerShell 5.1 (`powershell.exe`), which the launcher invokes.

## Bug reports

Include Windows version, Claude version, Node version, reproduction steps, relevant `patch.log` lines,
and security-state output. Remove sensitive information before posting publicly.
