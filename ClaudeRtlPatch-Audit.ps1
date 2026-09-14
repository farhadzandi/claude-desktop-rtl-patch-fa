<#
Claude RTL Patch Security Audit v1.1
READ-ONLY by default. This version expands checks for:
- all local user profiles (Desktop / Temp / LocalAppData)
- any related scheduled task, not only the expected task name
- related Run/RunOnce registry persistence
- broad self-signed Claude/Anthropic code-signing certificates
- WindowsApps Claude ACL/ownership changes caused by takeown/icacls
- Defender state/exclusions with SecurityCenter fallback
- URLs and execution primitives in ProgramData updater scripts

Usage:
  powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-Audit-v1.1.ps1
  powershell -ExecutionPolicy Bypass -File .\ClaudeRtlPatch-Audit-v1.1.ps1 -ExportReport
#>
[CmdletBinding()]
param([switch]$ExportReport)

$ErrorActionPreference = 'Continue'
$Findings = New-Object System.Collections.Generic.List[object]

function Add-Finding {
    param([string]$Severity,[string]$Category,[string]$Item,[string]$Detail)
    $Findings.Add([pscustomobject]@{
        Severity=$Severity; Category=$Category; Item=$Item; Detail=$Detail
    }) | Out-Null
}
function H([string]$s){ Write-Host ""; Write-Host "=== $s ===" -ForegroundColor Cyan }
function Hash([string]$p){
    if(Test-Path -LiteralPath $p){
        try { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() } catch {}
    }
}
function Sig([string]$p){
    if(Test-Path -LiteralPath $p){
        try {
            $s=Get-AuthenticodeSignature -LiteralPath $p
            [pscustomobject]@{
                Status=[string]$s.Status
                Subject=if($s.SignerCertificate){$s.SignerCertificate.Subject}else{''}
                Issuer=if($s.SignerCertificate){$s.SignerCertificate.Issuer}else{''}
                Thumbprint=if($s.SignerCertificate){$s.SignerCertificate.Thumbprint}else{''}
            }
        } catch {}
    }
}
function Get-ClaudeDirs {
    $d=@()
    try {
        Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
          Where-Object {$_.Name -like '*Claude*' -and $_.InstallLocation -and (Test-Path $_.InstallLocation)} |
          ForEach-Object {$d += $_.InstallLocation}
    } catch {
        try {
            Get-AppxPackage -ErrorAction SilentlyContinue |
              Where-Object {$_.Name -like '*Claude*' -and $_.InstallLocation -and (Test-Path $_.InstallLocation)} |
              ForEach-Object {$d += $_.InstallLocation}
        } catch {}
    }
    $legacy=Join-Path $env:LOCALAPPDATA 'AnthropicClaude'
    if(Test-Path $legacy){$d += $legacy}
    @($d | Sort-Object -Unique)
}

$admin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
Write-Host ""
Write-Host "Claude RTL Patch Security Audit v1.1" -ForegroundColor Green
Write-Host "Mode: READ-ONLY"
Write-Host "Administrator: $admin"
Write-Host "Running identity: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"

# 1. Certificates
H "Certificates"
$relatedCerts=@()
foreach($store in @('Cert:\LocalMachine\Root','Cert:\LocalMachine\My','Cert:\CurrentUser\Root','Cert:\CurrentUser\My')){
    try {
        Get-ChildItem $store -ErrorAction SilentlyContinue | ForEach-Object {
            $eku = @($_.EnhancedKeyUsageList | ForEach-Object {$_.ObjectId.Value})
            $isCodeSigning = $eku -contains '1.3.6.1.5.5.7.3.3'
            $nameHit = $_.FriendlyName -match 'Claude|RTL|Anthropic' -or $_.Subject -match 'Claude|Anthropic'
            $selfSigned = $_.Subject -eq $_.Issuer
            if($nameHit -or ($selfSigned -and $isCodeSigning)){
                $o=[pscustomobject]@{
                    Store=$store; Subject=$_.Subject; Issuer=$_.Issuer; Thumbprint=$_.Thumbprint
                    FriendlyName=$_.FriendlyName; SelfSigned=$selfSigned
                    CodeSigning=$isCodeSigning; HasPrivateKey=$_.HasPrivateKey; NotAfter=$_.NotAfter
                }
                $relatedCerts += $o
                $sev='INFO'
                if($_.FriendlyName -eq 'Claude_RTL_SelfSigned' -or
                   ($selfSigned -and $_.Subject -match 'Claude RTL|CN=Anthropic PBC')){
                    $sev=if($_.HasPrivateKey){'HIGH'}else{'MEDIUM'}
                    Add-Finding $sev 'Certificate' $_.Thumbprint "$store | $($_.Subject) | PrivateKey=$($_.HasPrivateKey)"
                }
            }
        }
    } catch {}
}
if($relatedCerts.Count){$relatedCerts | Format-Table -Wrap -AutoSize | Out-Host}
else{Write-Host "[OK] No related or self-signed code-signing certificate found."}

# 2. Scheduled tasks - broad action scan
H "Scheduled Tasks"
$taskHits=@()
try {
    foreach($t in Get-ScheduledTask -ErrorAction SilentlyContinue){
        $act=($t.Actions | ForEach-Object {"$($_.Execute) $($_.Arguments) $($_.WorkingDirectory)"}) -join ' | '
        if($t.TaskName -match 'Claude.*RTL|RTL.*Claude|ClaudeRtlPatch' -or
           $act -match 'ClaudeRtlPatch|claude_rtl_patch|shraga100|patch\.ps1'){
            $taskHits += [pscustomobject]@{TaskPath=$t.TaskPath;TaskName=$t.TaskName;State=$t.State;Action=$act}
            Add-Finding 'MEDIUM' 'Persistence' "$($t.TaskPath)$($t.TaskName)" $act
        }
    }
} catch {}
if($taskHits.Count){$taskHits | Format-Table -Wrap -AutoSize | Out-Host}
else{Write-Host "[OK] No related scheduled task/action found."}

# 3. Run / RunOnce persistence
H "Run / RunOnce"
$runHits=@()
$runKeys=@(
 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',
 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce'
)
foreach($rk in $runKeys){
    if(Test-Path $rk){
        try {
            $p=Get-ItemProperty $rk
            foreach($prop in $p.PSObject.Properties){
                if($prop.Name -notmatch '^PS' -and [string]$prop.Value -match 'ClaudeRtlPatch|claude_rtl_patch|shraga100|patch\.ps1'){
                    $runHits += [pscustomobject]@{Key=$rk;Name=$prop.Name;Value=[string]$prop.Value}
                    Add-Finding 'HIGH' 'Persistence' "$rk\$($prop.Name)" ([string]$prop.Value)
                }
            }
        } catch {}
    }
}
if($runHits.Count){$runHits | Format-Table -Wrap -AutoSize | Out-Host}
else{Write-Host "[OK] No related Run/RunOnce entry found."}

# 4. All local profiles
H "Per-user artifacts"
$profileHits=@()
$usersRoot='C:\Users'
if(Test-Path $usersRoot){
    Get-ChildItem $usersRoot -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $u=$_.FullName
        $candidates=@(
            (Join-Path $u 'Desktop\Update Claude RTL.lnk'),
            (Join-Path $u 'AppData\Local\Temp\claude_rtl_patch.ps1'),
            (Join-Path $u 'AppData\Local\Temp\claude_rtl_patch_tmp'),
            (Join-Path $u 'AppData\Local\ClaudeRtlPatch')
        )
        foreach($c in $candidates){
            if(Test-Path -LiteralPath $c){
                $profileHits += [pscustomobject]@{Profile=$u;Path=$c}
                Add-Finding 'LOW' 'Per-user artifact' $c 'Related file/folder remains.'
            }
        }
    }
}
$publicLnk='C:\Users\Public\Desktop\Update Claude RTL.lnk'
if(Test-Path $publicLnk){
    $profileHits += [pscustomobject]@{Profile='Public';Path=$publicLnk}
    Add-Finding 'LOW' 'Per-user artifact' $publicLnk 'Related shortcut remains.'
}
if($profileHits.Count){$profileHits | Format-Table -AutoSize | Out-Host}
else{Write-Host "[OK] No per-user related artifact found."}

# 5. ProgramData updater/cache
H "ProgramData"
$stateDir=Join-Path $env:ProgramData 'ClaudeRtlPatch'
if(Test-Path $stateDir){
    Write-Host "[FOUND] $stateDir"
    Get-ChildItem $stateDir -Force | Select-Object Name,Length,LastWriteTime | Format-Table -AutoSize | Out-Host
    Add-Finding 'LOW' 'Artifacts' $stateDir 'Patch state/cache exists.'
    foreach($f in Get-ChildItem $stateDir -File -ErrorAction SilentlyContinue){
        $h=Hash $f.FullName
        Write-Host "  SHA256 $($f.Name): $h"
        if($f.Extension -eq '.ps1'){
            $txt=Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
            $urls=[regex]::Matches($txt,'https?://[^\s"''`)]+') | ForEach-Object {$_.Value} | Sort-Object -Unique
            $exec=@()
            foreach($needle in @('DownloadData','DownloadString','Invoke-RestMethod','Invoke-WebRequest','Invoke-Expression','Start-Process','-EncodedCommand')){
                if($txt -match [regex]::Escape($needle)){$exec += $needle}
            }
            if($urls.Count -or $exec.Count){
                Write-Host "  $($f.Name) URLs: $($urls -join ', ')"
                Write-Host "  $($f.Name) primitives: $($exec -join ', ')"
                Add-Finding 'MEDIUM' 'Network-capable artifact' $f.FullName ("URLs="+($urls -join ', ')+" | primitives="+($exec -join ', '))
            }
        }
    }
} else {Write-Host "[OK] ProgramData patch directory not found."}

# 6. Defender / installed AV
H "Defender / Antivirus"
$defenderRead=$false
try {
    $mp=Get-MpComputerStatus -ErrorAction Stop
    $defenderRead=$true
    $mp | Select-Object AMServiceEnabled,AntivirusEnabled,RealTimeProtectionEnabled,
        AntivirusSignatureLastUpdated | Format-List | Out-Host
} catch {
    Write-Host "[INFO] Get-MpComputerStatus unavailable: $($_.Exception.Message)"
}
try {
    $pref=Get-MpPreference -ErrorAction Stop
    $defenderRead=$true
    $related=@()
    foreach($x in @($pref.ExclusionPath)){if($x -match 'Claude|Anthropic|ClaudeRtlPatch'){$related += "Path: $x"}}
    foreach($x in @($pref.ExclusionProcess)){if($x -match 'Claude|Anthropic|powershell|node|npx'){$related += "Process: $x"}}
    if($related.Count){
        $related | ForEach-Object {Write-Host "[WARN] $_"}
        Add-Finding 'HIGH' 'Defender exclusion' 'Related exclusion' ($related -join '; ')
    } else { Write-Host "[OK] No related Defender exclusion found." }
} catch {
    Write-Host "[INFO] Get-MpPreference unavailable: $($_.Exception.Message)"
}
try {
    $av=Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct -ErrorAction Stop |
        Select-Object displayName,pathToSignedProductExe,productState
    if($av){Write-Host "Registered antivirus products:"; $av | Format-Table -AutoSize | Out-Host}
} catch {}
if(-not $defenderRead){Add-Finding 'INFO' 'Defender' 'Status' 'Defender cmdlets could not be queried.'}

# 7. Claude package, signatures, backups and ACL changes
H "Claude Files / ACL"
$dirs=Get-ClaudeDirs
foreach($dir in $dirs){
    Write-Host ""
    Write-Host "Install: $dir" -ForegroundColor Yellow

    foreach($aclPath in @((Join-Path $dir 'app'),(Join-Path $dir 'app\resources'))){
        if(Test-Path $aclPath){
            try {
                $acl=Get-Acl -LiteralPath $aclPath
                Write-Host "  ACL: $aclPath"
                Write-Host "    Owner: $($acl.Owner)"
                $explicitAdminFull=@($acl.Access | Where-Object {
                    -not $_.IsInherited -and
                    $_.AccessControlType -eq 'Allow' -and
                    $_.IdentityReference -match 'Administrators|S-1-5-32-544' -and
                    ([string]$_.FileSystemRights -match 'FullControl')
                })
                if($acl.Owner -match 'Administrators|S-1-5-32-544' -or $explicitAdminFull.Count){
                    Add-Finding 'MEDIUM' 'ACL modification evidence' $aclPath ("Owner=$($acl.Owner); ExplicitAdminFullControl=$($explicitAdminFull.Count)")
                    Write-Host "    [WARN] Ownership/explicit Administrators FullControl may reflect patch takeown/icacls."
                }
            } catch {}
        }
    }

    $targets=@(
      (Join-Path $dir 'app\claude.exe'),
      (Join-Path $dir 'app\resources\cowork-svc.exe'),
      (Join-Path $dir 'app\resources\app.asar')
    )
    foreach($live in $targets | Where-Object {Test-Path $_}){
        $lh=Hash $live; $bak="$live.bak"; $bh=Hash $bak
        Write-Host "  $live"
        Write-Host "    SHA256: $lh"
        if($live -match '\.exe$'){
            $s=Sig $live
            if($s){Write-Host "    Signature: $($s.Status) | $($s.Subject) | Thumbprint=$($s.Thumbprint)"}
        }
        if(Test-Path $bak){
            Write-Host "    Backup SHA256: $bh"
            if($lh -eq $bh){
                Write-Host "    [OK] Live file is byte-identical to .bak"
            } else {
                Add-Finding 'MEDIUM' 'Modified Claude file' $live "Live SHA256 differs from .bak."
                Write-Host "    [WARN] Live file differs from .bak"
            }
        }
    }
}

# 8. Services/processes
H "Claude services / processes"
try {
    Get-CimInstance Win32_Service -ErrorAction SilentlyContinue |
      Where-Object {$_.PathName -match 'Claude|cowork-svc'} |
      Select-Object Name,State,StartMode,PathName | Format-Table -Wrap -AutoSize | Out-Host
} catch {}
Get-Process -Name claude,cowork-svc -ErrorAction SilentlyContinue |
  Select-Object Name,Id,Path | Format-Table -AutoSize | Out-Host

# 9. Summary
H "Summary"
if($Findings.Count){
    $rank=@{HIGH=1;MEDIUM=2;LOW=3;INFO=4}
    $Findings | Sort-Object @{Expression={$rank[$_.Severity]}},Category |
      Format-Table Severity,Category,Item,Detail -Wrap -AutoSize | Out-Host
}else{
    Write-Host "No known RTL-patch artifact/security finding detected." -ForegroundColor Green
}

if($ExportReport){
    $dest='C:\Users\Public\Desktop'
    if(-not (Test-Path $dest)){ $dest=[Environment]::GetFolderPath('Desktop') }
    $out=Join-Path $dest ("ClaudeRtlPatch-Audit-v1.1-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    [pscustomobject]@{
        Timestamp=(Get-Date).ToString('o')
        RunningIdentity=[Security.Principal.WindowsIdentity]::GetCurrent().Name
        Administrator=$admin
        Findings=$Findings
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $out -Encoding UTF8
    Write-Host ""
    Write-Host "[+] JSON report: $out" -ForegroundColor Green
}
