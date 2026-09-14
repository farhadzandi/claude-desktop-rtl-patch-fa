<#
Claude RTL Patch Cleanup v1.0
Purpose: remove known residual artifacts of the RTL patch WITHOUT guessing WindowsApps ACLs.

Default mode is DRY-RUN. Nothing is changed unless -Apply is supplied.

Usage:
  powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-Cleanup-v1.0.ps1
  powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-Cleanup-v1.0.ps1 -Apply

What -Apply removes:
- ClaudeRtlPatchWatcher scheduled task (if present)
- known self-signed RTL patch certificates (only matching the patch's known identity/friendly name)
- C:\ProgramData\ClaudeRtlPatch (after backing it up as ZIP)
- per-user temp/local cache artifacts created by the patch
- "Update Claude RTL.lnk" shortcuts

What it deliberately does NOT change:
- C:\Program Files\WindowsApps ACL/owner settings
- Claude program files
- .bak files inside the Claude package

For ACL/owner restoration, uninstall/reinstall the official Claude Desktop package.
#>

[CmdletBinding()]
param([switch]$Apply)

$ErrorActionPreference = "Continue"

function Is-Admin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}
function Banner($s) {
    Write-Host ""
    Write-Host "=== $s ===" -ForegroundColor Cyan
}
function SayPlan($s) {
    if ($Apply) { Write-Host "[APPLY] $s" -ForegroundColor Yellow }
    else { Write-Host "[DRY-RUN] $s" -ForegroundColor DarkYellow }
}

Write-Host ""
Write-Host "Claude RTL Patch Cleanup v1.0" -ForegroundColor Green
Write-Host ("Mode: " + $(if ($Apply) {"APPLY"} else {"DRY-RUN"}))

if ($Apply -and -not (Is-Admin)) {
    Write-Host "[ERROR] -Apply requires Run as Administrator." -ForegroundColor Red
    exit 2
}

# 1. Scheduled task
Banner "Scheduled Task"
$task = Get-ScheduledTask -TaskName "ClaudeRtlPatchWatcher" -ErrorAction SilentlyContinue
if ($task) {
    SayPlan "Remove scheduled task ClaudeRtlPatchWatcher"
    if ($Apply) {
        try {
            Stop-ScheduledTask -TaskName "ClaudeRtlPatchWatcher" -ErrorAction SilentlyContinue
            Unregister-ScheduledTask -TaskName "ClaudeRtlPatchWatcher" -Confirm:$false -ErrorAction Stop
            Write-Host "[OK] Scheduled task removed." -ForegroundColor Green
        } catch { Write-Host "[WARN] $($_.Exception.Message)" -ForegroundColor Red }
    }
} else {
    Write-Host "[OK] Scheduled task not present."
}

# 2. Known patch certificates only
Banner "Certificates"
$certs = @()
foreach ($store in @("Cert:\LocalMachine\Root","Cert:\LocalMachine\My","Cert:\CurrentUser\Root","Cert:\CurrentUser\My")) {
    try {
        $certs += Get-ChildItem $store -ErrorAction SilentlyContinue | Where-Object {
            (
                $_.FriendlyName -eq "Claude_RTL_SelfSigned" -or
                $_.Subject -match "^CN=Claude RTL Local Patch" -or
                $_.Subject -eq "CN=Anthropic PBC, O=Anthropic PBC, L=San Francisco, S=California, C=US"
            ) -and ($_.Subject -eq $_.Issuer)
        } | ForEach-Object {
            [pscustomobject]@{
                Store=$store; Thumbprint=$_.Thumbprint; Subject=$_.Subject; HasPrivateKey=$_.HasPrivateKey; PSPath=$_.PSPath
            }
        }
    } catch {}
}
if ($certs.Count) {
    $certs | Select-Object Store,Thumbprint,Subject,HasPrivateKey | Format-Table -Wrap -AutoSize | Out-Host
    foreach ($c in $certs) {
        SayPlan "Remove self-signed patch certificate $($c.Thumbprint) from $($c.Store)"
        if ($Apply) {
            try {
                Remove-Item -LiteralPath $c.PSPath -Force -ErrorAction Stop
                Write-Host "[OK] Removed $($c.Thumbprint)" -ForegroundColor Green
            } catch { Write-Host "[WARN] $($_.Exception.Message)" -ForegroundColor Red }
        }
    }
} else {
    Write-Host "[OK] No known self-signed RTL patch certificate present."
}

# 3. ProgramData state/cache - backup first
Banner "ProgramData"
$stateDir = Join-Path $env:ProgramData "ClaudeRtlPatch"
if (Test-Path $stateDir) {
    $backupDir = "C:\Users\Public\Desktop"
    if (-not (Test-Path $backupDir)) { $backupDir = [Environment]::GetFolderPath("Desktop") }
    $zip = Join-Path $backupDir ("ClaudeRtlPatch-residual-backup-{0}.zip" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    SayPlan "Backup $stateDir to $zip, then remove the directory"
    if ($Apply) {
        try {
            Compress-Archive -Path (Join-Path $stateDir "*") -DestinationPath $zip -Force -ErrorAction Stop
            Write-Host "[OK] Residual backup created: $zip" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Backup failed; ProgramData folder will NOT be removed. $($_.Exception.Message)" -ForegroundColor Red
            $zip = $null
        }
        if ($zip) {
            try {
                Remove-Item -LiteralPath $stateDir -Recurse -Force -ErrorAction Stop
                Write-Host "[OK] Removed $stateDir" -ForegroundColor Green
            } catch { Write-Host "[WARN] $($_.Exception.Message)" -ForegroundColor Red }
        }
    }
} else {
    Write-Host "[OK] ProgramData patch directory not present."
}

# 4. All local user profile residues
Banner "Per-user residues"
$targets = New-Object System.Collections.Generic.List[string]
if (Test-Path "C:\Users") {
    Get-ChildItem "C:\Users" -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $u = $_.FullName
        foreach ($rel in @(
            "AppData\Local\Temp\claude_rtl_patch.ps1",
            "AppData\Local\Temp\claude_rtl_patch_tmp",
            "AppData\Local\ClaudeRtlPatch",
            "Desktop\Update Claude RTL.lnk"
        )) {
            $p = Join-Path $u $rel
            if (Test-Path -LiteralPath $p) { $targets.Add($p) | Out-Null }
        }
    }
}
$publicShortcut = "C:\Users\Public\Desktop\Update Claude RTL.lnk"
if (Test-Path $publicShortcut) { $targets.Add($publicShortcut) | Out-Null }

if ($targets.Count) {
    foreach ($p in $targets | Sort-Object -Unique) {
        SayPlan "Remove $p"
        if ($Apply) {
            try {
                Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction Stop
                Write-Host "[OK] Removed $p" -ForegroundColor Green
            } catch { Write-Host "[WARN] Could not remove $p : $($_.Exception.Message)" -ForegroundColor Red }
        }
    }
} else {
    Write-Host "[OK] No per-user patch residue found."
}

# 5. Safety note for WindowsApps ACL
Banner "WindowsApps ACL"
Write-Host "This cleaner intentionally does NOT reset owner/ACL on Claude's WindowsApps package." -ForegroundColor Yellow
Write-Host "Reason: the original package ACL was not captured before takeown/icacls, so guessing it could damage the MSIX package."
Write-Host "Recommended fix: uninstall Claude Desktop, reboot if prompted, then reinstall the official current Claude Desktop package."
Write-Host "After reinstall, re-run ClaudeRtlPatch-Audit-v1.1.ps1 to verify the ACL findings are gone."

if (-not $Apply) {
    Write-Host ""
    Write-Host "No changes were made. Re-run with -Apply if the dry-run list looks correct." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Cleanup finished. Program files and WindowsApps ACLs were not modified." -ForegroundColor Green
}
