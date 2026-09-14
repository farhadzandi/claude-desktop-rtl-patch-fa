# Full installation, update, and removal guide

## Requirements

- Windows 10/11 x64
- Claude Desktop installed
- Windows PowerShell 5.1
- Node.js >= 22.12.0
- `npx`
- Administrator/UAC access

Check:

```powershell
node --version
npx --version
```

## Download

Clone:

```powershell
git clone https://github.com/farhadzandi/claude-desktop-rtl-patch-fa.git
cd claude-desktop-rtl-patch-fa
```

Or download the latest GitHub Release ZIP and fully extract it.

## Verify the package

```powershell
powershell -ExecutionPolicy Bypass -File .\Verify-Package.ps1
```

Do not continue if any file is missing or has a hash mismatch.

## If older RTL patch builds were used

Run the read-only audit:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-Audit.ps1 -ExportReport
```

If legacy ACL residue is detected, first dry-run:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-ACL-Repair.ps1
```

Only after reviewing the output:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-ACL-Repair.ps1 -Apply
```

## Install

Run:

```text
run-patch.bat
```

or:

```powershell
powershell -ExecutionPolicy Bypass -File .\patch.ps1
```

Choose `1. Install / Re-Apply Persian RTL Patch`.

The patch temporarily stops Claude, snapshots relevant ACL/owner state, creates secure vendor backups,
modifies the Electron ASAR and Claude-specific integrity/signing path, destroys the temporary signing
private key, restores ACL/owner state, verifies the restore, and starts Claude again.

## Verify after installation

```powershell
powershell -ExecutionPolicy Bypass -File .\Verify-Security-State.ps1 -ExportReport
```

## Custom font

Install the font on Windows first, then use menu option 3. Example:

```powershell
powershell -ExecutionPolicy Bypass -File .\patch.ps1 -CustomFont "Vazirmatn" -CustomFontScope persian
```

## Claude Desktop updates

This build intentionally has no auto-repatch. After an update, manually run the patcher and choose
install/re-apply again.

## Restore

Run the patcher and choose `2. Restore Original Claude Files & Remove Patch`.

## Legacy residue cleanup

Dry-run:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-Cleanup.ps1
```

Apply only after reviewing the dry-run:

```powershell
powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-Cleanup.ps1 -Apply
```

## Risk statement

This project modifies local Claude Desktop application files and performs privileged operations.
“Hardened” means the patch attempts to minimize, snapshot, verify, and roll back those operations;
it does not mean the process is risk-free.
