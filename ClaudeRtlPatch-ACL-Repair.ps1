<#
Claude RTL Patch ACL Repair v1.0
Targeted cleanup for the known takeown/icacls residue left by the RTL patch.

DEFAULT = DRY-RUN. Nothing is changed unless -Apply is supplied.

What it repairs:
  1) Removes ONLY explicit BUILTIN\Administrators FullControl ACEs inside Claude's "app" tree.
     It does NOT remove inherited Administrators Read/Execute permissions.
  2) Restores owner of Claude's "app" tree to SYSTEM, but ONLY if the package root owner is SYSTEM.
  3) Optionally removes the three known .bak files, ONLY when each backup is byte-identical
     to the live file; executable live files must also have a valid Anthropic signature.

What it does NOT change:
  - The package-root ACL.
  - AppContainer capability ACEs.
  - TrustedInstaller/SYSTEM/Users/Local Service/Network Service rules.
  - Claude file contents.
  - Any certificate, scheduled task, registry setting, firewall rule, or Defender setting.

Usage:
  # Dry-run:
  powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-ACL-Repair-v1.0.ps1

  # Apply after reviewing dry-run:
  powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-ACL-Repair-v1.0.ps1 -Apply
#>

[CmdletBinding()]
param(
    [switch]$Apply
)

$ErrorActionPreference = "Continue"
$AdminSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
$SystemSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")

function Is-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Section([string]$Name) {
    Write-Host ""
    Write-Host "=== $Name ===" -ForegroundColor Cyan
}

function Get-ClaudePackagePath {
    $pkgs = @()
    try {
        $pkgs = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "*Claude*" -and $_.InstallLocation -and (Test-Path $_.InstallLocation) }
    } catch {}
    if (-not $pkgs) {
        try {
            $pkgs = Get-AppxPackage -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like "*Claude*" -and $_.InstallLocation -and (Test-Path $_.InstallLocation) }
        } catch {}
    }
    if ($pkgs) {
        return ($pkgs | Sort-Object Version -Descending | Select-Object -First 1).InstallLocation
    }
    return $null
}

function Get-AllNodes([string]$Root) {
    $items = New-Object System.Collections.Generic.List[string]
    $items.Add($Root) | Out-Null
    try {
        Get-ChildItem -LiteralPath $Root -Force -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object { $items.Add($_.FullName) | Out-Null }
    } catch {}
    return @($items)
}

function Is-ExplicitAdminFullControlRule($Rule) {
    try {
        $sid = $Rule.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier])
        return (
            -not $Rule.IsInherited -and
            $sid.Value -eq $AdminSid.Value -and
            $Rule.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Allow -and
            (($Rule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::FullControl) -eq
             [System.Security.AccessControl.FileSystemRights]::FullControl)
        )
    } catch {
        return $false
    }
}

function Get-Sha256([string]$Path) {
    try { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant() }
    catch { return $null }
}

function Get-Sig([string]$Path) {
    try {
        $s = Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop
        [pscustomobject]@{
            Status = [string]$s.Status
            Subject = if ($s.SignerCertificate) { $s.SignerCertificate.Subject } else { "" }
        }
    } catch { return $null }
}

Write-Host ""
Write-Host "Claude RTL Patch ACL Repair v1.0" -ForegroundColor Green
Write-Host ("Mode: " + $(if ($Apply) { "APPLY" } else { "DRY-RUN" }))
Write-Host "Running identity: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Host "Administrator: $(Is-Admin)"

if ($Apply -and -not (Is-Admin)) {
    Write-Host "[ERROR] -Apply requires Run as Administrator." -ForegroundColor Red
    exit 2
}

$root = Get-ClaudePackagePath
if (-not $root) {
    Write-Host "[ERROR] Claude package was not found." -ForegroundColor Red
    exit 3
}
$app = Join-Path $root "app"
if (-not (Test-Path -LiteralPath $app)) {
    Write-Host "[ERROR] Claude app directory was not found: $app" -ForegroundColor Red
    exit 4
}

$rootAcl = Get-Acl -LiteralPath $root
$rootOwnerSid = $null
try {
    $rootOwnerSid = (New-Object System.Security.Principal.NTAccount($rootAcl.Owner)).Translate(
        [System.Security.Principal.SecurityIdentifier]
    )
} catch {}

Write-Host "Package: $root"
Write-Host "Package-root owner: $($rootAcl.Owner)"

# Fail closed: this repair is designed for the observed MSIX state only.
if (-not $rootOwnerSid -or $rootOwnerSid.Value -ne $SystemSid.Value) {
    Write-Host "[REFUSE] Package root owner is not SYSTEM. No repair will be performed." -ForegroundColor Red
    Write-Host "Expected S-1-5-18; observed: $($rootAcl.Owner)"
    exit 5
}

$nodes = Get-AllNodes $app

Section "Current ACL residue"
$ownerBad = New-Object System.Collections.Generic.List[string]
$explicitRules = New-Object System.Collections.Generic.List[object]

foreach ($p in $nodes) {
    try {
        $acl = Get-Acl -LiteralPath $p -ErrorAction Stop

        $ownerSid = $null
        try {
            $ownerSid = (New-Object System.Security.Principal.NTAccount($acl.Owner)).Translate(
                [System.Security.Principal.SecurityIdentifier]
            )
        } catch {}

        if (-not $ownerSid -or $ownerSid.Value -ne $SystemSid.Value) {
            $ownerBad.Add($p) | Out-Null
        }

        foreach ($r in $acl.Access) {
            if (Is-ExplicitAdminFullControlRule $r) {
                $explicitRules.Add([pscustomobject]@{
                    Path = $p
                    Identity = [string]$r.IdentityReference
                    Rights = [string]$r.FileSystemRights
                    InheritanceFlags = [string]$r.InheritanceFlags
                    PropagationFlags = [string]$r.PropagationFlags
                }) | Out-Null
            }
        }
    } catch {
        Write-Host "[WARN] Could not inspect: $p : $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "Items whose owner differs from package-root SYSTEM owner: $($ownerBad.Count)"
Write-Host "Explicit Administrators FullControl ACEs to remove: $($explicitRules.Count)"

if ($ownerBad.Count -le 20) {
    $ownerBad | ForEach-Object { Write-Host "  OWNER: $_" }
} else {
    $ownerBad | Select-Object -First 20 | ForEach-Object { Write-Host "  OWNER: $_" }
    Write-Host "  ... plus $($ownerBad.Count - 20) more"
}

if ($explicitRules.Count) {
    $explicitRules | Select-Object -First 30 | Format-Table -AutoSize | Out-Host
    if ($explicitRules.Count -gt 30) { Write-Host "... plus $($explicitRules.Count - 30) more explicit ACE(s)." }
}

Section "Known backup files"
$backupPairs = @(
    [pscustomobject]@{ Live=(Join-Path $app "claude.exe"); Bak=(Join-Path $app "claude.exe.bak"); RequireAnthropic=$true },
    [pscustomobject]@{ Live=(Join-Path $app "resources\cowork-svc.exe"); Bak=(Join-Path $app "resources\cowork-svc.exe.bak"); RequireAnthropic=$true },
    [pscustomobject]@{ Live=(Join-Path $app "resources\app.asar"); Bak=(Join-Path $app "resources\app.asar.bak"); RequireAnthropic=$false }
)

$removableBackups = New-Object System.Collections.Generic.List[string]
foreach ($pair in $backupPairs) {
    if (-not (Test-Path -LiteralPath $pair.Bak)) {
        Write-Host "[OK] No backup: $($pair.Bak)"
        continue
    }
    if (-not (Test-Path -LiteralPath $pair.Live)) {
        Write-Host "[KEEP] Backup exists but live file is missing: $($pair.Bak)" -ForegroundColor Yellow
        continue
    }

    $lh = Get-Sha256 $pair.Live
    $bh = Get-Sha256 $pair.Bak
    $same = ($lh -and $bh -and $lh -eq $bh)
    $sigOK = $true
    $sigDesc = ""

    if ($pair.RequireAnthropic) {
        $sig = Get-Sig $pair.Live
        $sigOK = ($sig -and $sig.Status -eq "Valid" -and $sig.Subject -match "Anthropic")
        $sigDesc = if ($sig) { "$($sig.Status) | $($sig.Subject)" } else { "unavailable" }
    }

    Write-Host "Backup: $($pair.Bak)"
    Write-Host "  Live SHA256:   $lh"
    Write-Host "  Backup SHA256: $bh"
    if ($pair.RequireAnthropic) { Write-Host "  Live signature: $sigDesc" }

    if ($same -and $sigOK) {
        Write-Host "  [SAFE-TO-REMOVE] Backup is byte-identical to verified live file." -ForegroundColor Green
        $removableBackups.Add($pair.Bak) | Out-Null
    } else {
        Write-Host "  [KEEP] Safety checks did not pass." -ForegroundColor Yellow
    }
}

if (-not $Apply) {
    Section "Dry-run result"
    Write-Host "No changes were made." -ForegroundColor Green
    Write-Host "If the counts and backup checks above look correct, run again with -Apply."
    exit 0
}

# Create a forensic pre-repair report and ACL save.
Section "Pre-repair backup"
$reportDir = "C:\Users\Public\Desktop"
if (-not (Test-Path $reportDir)) { $reportDir = [Environment]::GetFolderPath("Desktop") }
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$jsonPath = Join-Path $reportDir "ClaudeRtlPatch-ACL-PreRepair-$stamp.json"
$aclSavePath = Join-Path $reportDir "ClaudeRtlPatch-ACL-PreRepair-$stamp.acl"

$pre = [pscustomobject]@{
    Timestamp = (Get-Date).ToString("o")
    Package = $root
    RootOwner = $rootAcl.Owner
    OwnerMismatchCount = $ownerBad.Count
    OwnerMismatchPaths = @($ownerBad)
    ExplicitAdminFullControlCount = $explicitRules.Count
    ExplicitAdminFullControl = @($explicitRules)
    RemovableBackups = @($removableBackups)
}
$pre | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
Write-Host "[OK] Pre-repair JSON: $jsonPath"

# Save DACL state with icacls as an additional rollback artifact.
try {
    cmd.exe /c "icacls `"$app`" /save `"$aclSavePath`" /T /C /Q" | Out-Null
    if (Test-Path -LiteralPath $aclSavePath) {
        Write-Host "[OK] Pre-repair ACL backup: $aclSavePath"
    } else {
        Write-Host "[WARN] icacls ACL backup was not created." -ForegroundColor Yellow
    }
} catch {
    Write-Host "[WARN] Could not save ACL backup: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Stop Claude/Cowork while ACLs are repaired.
Section "Stopping Claude"
$svc = Get-Service -Name "CoworkVMService" -ErrorAction SilentlyContinue
$svcWasRunning = ($svc -and $svc.Status -eq "Running")
if ($svcWasRunning) {
    try {
        Stop-Service -Name "CoworkVMService" -Force -ErrorAction Stop
        Write-Host "[OK] CoworkVMService stopped."
    } catch { Write-Host "[WARN] Could not stop CoworkVMService: $($_.Exception.Message)" -ForegroundColor Yellow }
}
Get-Process -Name "claude","cowork-svc" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

# Remove ONLY explicit BA FullControl ACEs, deepest paths first.
Section "Removing patch-added explicit Administrators FullControl ACEs"
$changedAcl = 0
$allPathsDeepFirst = $nodes | Sort-Object { $_.Length } -Descending

foreach ($p in $allPathsDeepFirst) {
    try {
        $acl = Get-Acl -LiteralPath $p -ErrorAction Stop
        $toRemove = @($acl.Access | Where-Object { Is-ExplicitAdminFullControlRule $_ })
        if ($toRemove.Count) {
            foreach ($r in $toRemove) {
                [void]$acl.RemoveAccessRuleSpecific($r)
            }
            Set-Acl -LiteralPath $p -AclObject $acl -ErrorAction Stop
            $changedAcl++
        }
    } catch {
        Write-Host "[WARN] ACL cleanup failed: $p : $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
Write-Host "[OK] ACL cleaned on $changedAcl item(s)."

# Restore owner to SYSTEM over the whole app tree.
Section "Restoring owner to SYSTEM"
try {
    $proc = Start-Process -FilePath "icacls.exe" `
        -ArgumentList @($app, "/setowner", "*S-1-5-18", "/T", "/C", "/Q") `
        -Wait -PassThru -WindowStyle Hidden
    if ($proc.ExitCode -eq 0) {
        Write-Host "[OK] Owner restore command completed."
    } else {
        Write-Host "[WARN] icacls exited with code $($proc.ExitCode)." -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERROR] Owner restore failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Remove only verified-identical backups.
Section "Removing verified duplicate backups"
foreach ($bak in $removableBackups) {
    try {
        Remove-Item -LiteralPath $bak -Force -ErrorAction Stop
        Write-Host "[OK] Removed: $bak"
    } catch {
        Write-Host "[WARN] Could not remove $bak : $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Restart service only if it was running before.
if ($svcWasRunning) {
    Section "Restarting CoworkVMService"
    try {
        Start-Service -Name "CoworkVMService" -ErrorAction Stop
        Write-Host "[OK] CoworkVMService started."
    } catch {
        Write-Host "[WARN] Could not restart CoworkVMService: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Verification.
Section "Verification"
$verifyNodes = Get-AllNodes $app
$badOwnerAfter = 0
$explicitAfter = 0
foreach ($p in $verifyNodes) {
    try {
        $acl = Get-Acl -LiteralPath $p -ErrorAction Stop
        $sid = $null
        try {
            $sid = (New-Object System.Security.Principal.NTAccount($acl.Owner)).Translate(
                [System.Security.Principal.SecurityIdentifier]
            )
        } catch {}
        if (-not $sid -or $sid.Value -ne $SystemSid.Value) { $badOwnerAfter++ }
        foreach ($r in $acl.Access) {
            if (Is-ExplicitAdminFullControlRule $r) { $explicitAfter++ }
        }
    } catch {}
}

Write-Host "Owner mismatches remaining: $badOwnerAfter"
Write-Host "Explicit Administrators FullControl ACEs remaining: $explicitAfter"

if ($badOwnerAfter -eq 0 -and $explicitAfter -eq 0) {
    Write-Host "[SUCCESS] Known ACL/ownership residue is repaired." -ForegroundColor Green
} else {
    Write-Host "[WARN] Repair is incomplete. Do not install another RTL patch yet." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next: run ClaudeRtlPatch-Audit-v1.1.ps1 again and review its JSON report."
