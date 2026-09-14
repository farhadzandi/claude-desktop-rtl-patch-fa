# Claude Desktop Persian RTL Patch — Secure Hardened v1.3.2

Persian-first smart RTL support for **Claude Desktop on Windows**, with rollback, ACL restoration,
security auditing, and post-install verification.

[راهنمای فارسی](README.fa.md) · [Full installation guide](docs/INSTALLATION.md) · [Troubleshooting](docs/TROUBLESHOOTING.md)

> [!IMPORTANT]
> This is a customized derivative of
> [`shraga100/claude-desktop-rtl-patch`](https://github.com/shraga100/claude-desktop-rtl-patch).
> The original RTL implementation and project are credited to **shraga100** and are distributed under
> the MIT License. The original copyright and license notice are preserved in `LICENSE`.
>
> This derivative is independently maintained and is **not affiliated with Anthropic**.

## Features

- Smart Persian/Arabic/Hebrew RTL detection.
- Keeps English, code blocks, file names, and technical content LTR.
- Better mixed Persian/English handling, tables, Persian digits, and math isolation.
- Optional installed-font override such as `Vazirmatn`.
- Secure backups and automatic rollback on failure.
- Exact-scope temporary ACL access with restoration and verification.
- Built-in package hash verification, audit, security-state verification, and legacy repair tools.

## Security-hardened policy

This build intentionally has **no** scheduled auto-repatch task, background watcher, remote
self-updater, quick-update persistence, Electron-fuse-disable fallback, or RSA-1024 fallback.

While patched, a public-only local Root certificate named `Claude RTL Local Patch` is expected.
The temporary private signing key must be destroyed successfully or installation rolls back.

See [`SECURITY.md`](SECURITY.md).

## Requirements

- Windows 10/11 x64
- Claude Desktop installed
- Windows PowerShell 5.1 (`powershell.exe`)
- Node.js >= 22.12.0 and `npx`
- Administrator rights
- Network access may be needed on first use for pinned `@electron/asar@4.2.0`

## Quick install

```powershell
git clone https://github.com/farhadzandi/claude-desktop-rtl-patch-fa.git
cd claude-desktop-rtl-patch-fa
powershell -ExecutionPolicy Bypass -File .\Verify-Package.ps1
.\run-patch.bat
```

Choose:

```text
1. Install / Re-Apply Persian RTL Patch
```

For ZIP releases: download the release ZIP, extract the entire archive, verify it with
`Verify-Package.ps1`, then run `run-patch.bat`.

This hardened build deliberately does **not** support `irm | iex`.

## Menu

```text
1. Install / Re-Apply Persian RTL Patch
2. Restore Original Claude Files & Remove Patch
3. Set Persian / Custom Text Font
4. Security & Maintenance
5. About / Attribution
6. Exit
```

Security & Maintenance includes package verification, read-only audit, current-state verification,
legacy ACL repair, and legacy-residue cleanup.

## Verify after install

```powershell
powershell -ExecutionPolicy Bypass -File .\Verify-Security-State.ps1 -ExportReport
```

## Restore

Run `run-patch.bat` and choose:

```text
2. Restore Original Claude Files & Remove Patch
```

## Claude updates

There is no auto-repatch. After a Claude Desktop update, run the installer manually again and choose
option 1. Unsupported new Claude layouts should fail closed rather than apply a guessed patch.

## Codex / ChatGPT Desktop

**Not supported in v1.3.2.** The Windows app exposes an Electron `app.asar`, but its integrity path
must not be assumed to match Claude. Support is deferred until a separate target-specific adapter can
be safely implemented. See [`ROADMAP.md`](ROADMAP.md).

## Documentation

- [`README.fa.md`](README.fa.md) — complete Persian overview
- [`docs/INSTALLATION.md`](docs/INSTALLATION.md) — detailed install/upgrade/restore
- [`docs/INSTALLATION.fa.md`](docs/INSTALLATION.fa.md) — راهنمای کامل فارسی
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)
- [`docs/TROUBLESHOOTING.fa.md`](docs/TROUBLESHOOTING.fa.md)
- [`SECURITY.md`](SECURITY.md)
- [`ATTRIBUTION.md`](ATTRIBUTION.md)
- [`CHANGELOG-fa.md`](CHANGELOG-fa.md)

## License

MIT. The original upstream MIT copyright and permission notice are preserved in `LICENSE`.
