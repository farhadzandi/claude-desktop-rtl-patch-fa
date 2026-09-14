<#
Claude Desktop Persian RTL Patch v1.3.2 - Security State Verifier
READ-ONLY. It does not modify Claude or Windows.

Checks:
- Claude package location and package-root owner
- app/resources/target-file ownership matches package root
- no explicit Administrators FullControl residue on patch targets
- no ClaudeRtlPatchWatcher scheduled task
- no legacy updater/watcher/local-cache scripts
- no private signing key left in LocalMachine\My
- if a Claude RTL self-signed Root cert exists, it must have no private key
- no adjacent .bak files inside WindowsApps
- secure backup location, if present, is under ProgramData\ClaudeRtlPatch\backups
#>
[CmdletBinding()]
param([switch]$ExportReport)

$ErrorActionPreference = 'Continue'
$findings = New-Object System.Collections.Generic.List[object]
function Add-Finding($Severity,$Category,$Item,$Detail) {
    $findings.Add([pscustomobject]@{Severity=$Severity;Category=$Category;Item=$Item;Detail=$Detail}) | Out-Null
}
function H($s){Write-Host "";Write-Host "=== $s ===" -ForegroundColor Cyan}
function OwnerSid($p){try{(Get-Acl -LiteralPath $p).GetOwner([System.Security.Principal.SecurityIdentifier]).Value}catch{$null}}
function RelatedAdminFull($p){
    try {
        @((Get-Acl -LiteralPath $p).Access | Where-Object {
            -not $_.IsInherited -and
            $_.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Allow -and
            $_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value -eq 'S-1-5-32-544' -and
            (($_.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::FullControl) -eq [System.Security.AccessControl.FileSystemRights]::FullControl)
        })
    } catch {@()}
}

$pkg=$null
try {
    $pkg=Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object {$_.Name -like '*Claude*' -and $_.InstallLocation -and (Test-Path $_.InstallLocation)} | Sort-Object {[version]$_.Version} -Descending | Select-Object -First 1
} catch {}
if(-not $pkg){
    try{$pkg=Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object {$_.Name -like '*Claude*' -and $_.InstallLocation -and (Test-Path $_.InstallLocation)} | Select-Object -First 1}catch{}
}
if(-not $pkg){Write-Host '[ERROR] Claude package not found.' -ForegroundColor Red; exit 2}
$root=$pkg.InstallLocation
$app=Join-Path $root 'app'
$res=Join-Path $app 'resources'
$targets=@($app,$res,(Join-Path $app 'claude.exe'),(Join-Path $res 'app.asar'),(Join-Path $res 'cowork-svc.exe'))

Write-Host "Claude RTL v1.3.2 Security Verifier" -ForegroundColor Green
Write-Host "Package: $root"
$rootOwner=OwnerSid $root
Write-Host "Package-root owner SID: $rootOwner"

H 'ACL / Ownership'
foreach($p in $targets){
    if(-not(Test-Path -LiteralPath $p)){Add-Finding 'HIGH' 'Missing target' $p 'Required Claude patch target is missing.';continue}
    $o=OwnerSid $p
    $bad=RelatedAdminFull $p
    Write-Host "$p"
    Write-Host "  owner=$o  explicit-admin-full=$($bad.Count)"
    if($o -ne $rootOwner){Add-Finding 'HIGH' 'ACL owner residue' $p "Owner $o differs from package owner $rootOwner."}
    if($bad.Count){Add-Finding 'HIGH' 'ACL permission residue' $p 'Explicit Administrators FullControl remains.'}
}

H 'Persistence'
$task=Get-ScheduledTask -TaskName 'ClaudeRtlPatchWatcher' -ErrorAction SilentlyContinue
if($task){Add-Finding 'HIGH' 'Persistence' 'ClaudeRtlPatchWatcher' 'Scheduled task exists; v1.3.2 does not install it.'; Write-Host '[WARN] Scheduled task exists.'}
else{Write-Host '[OK] No RTL scheduled task.'}
$stateDir=Join-Path $env:ProgramData 'ClaudeRtlPatch'
foreach($name in @('update.ps1','watcher.ps1','patch-fa.ps1','patch-fa.sha256','last-action.txt','trusted-pubkey.b64')){
    $f=Join-Path $stateDir $name
    if(Test-Path -LiteralPath $f){Add-Finding 'HIGH' 'Legacy persistence artifact' $f 'v1.3.2 should not leave this file.'}
}

H 'Certificates / Private Key'
$my=@(Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue | Where-Object {$_.FriendlyName -eq 'Claude_RTL_SelfSigned' -or $_.Subject -match '^CN=Claude RTL Local Patch'})
if($my.Count){
    foreach($c in $my){Add-Finding 'HIGH' 'Private signing cert' $c.Thumbprint "Certificate remains in LocalMachine\\My; HasPrivateKey=$($c.HasPrivateKey)"}
}else{Write-Host '[OK] No RTL signing certificate remains in LocalMachine\My.'}
$rootCerts=@(Get-ChildItem Cert:\LocalMachine\Root -ErrorAction SilentlyContinue | Where-Object {$_.FriendlyName -eq 'Claude_RTL_SelfSigned' -or $_.Subject -match '^CN=Claude RTL Local Patch'})
if($rootCerts.Count){
    foreach($c in $rootCerts){
        Write-Host "[INFO] Trusted RTL Root cert: $($c.Thumbprint), privateKey=$($c.HasPrivateKey)"
        if($c.HasPrivateKey){Add-Finding 'HIGH' 'Trusted root private key' $c.Thumbprint 'Trusted RTL Root certificate exposes a private key.'}
        else{Add-Finding 'INFO' 'Expected patched-state trust anchor' $c.Thumbprint 'Public-only RTL Root certificate exists. Expected while patch is installed; Restore removes it.'}
    }
}else{Write-Host '[INFO] No RTL Root cert. This is expected when Claude is restored/unpatched.'}

H 'WindowsApps backup residue'
$adjacent=@((Join-Path $app 'claude.exe.bak'),(Join-Path $res 'app.asar.bak'),(Join-Path $res 'cowork-svc.exe.bak'))
foreach($f in $adjacent){if(Test-Path -LiteralPath $f){Add-Finding 'MEDIUM' 'Legacy adjacent backup' $f 'v1.3.2 stores backups outside WindowsApps.'}}
$backupRoot=Join-Path $stateDir 'backups'
if(Test-Path $backupRoot){Write-Host "[OK] Secure backup root: $backupRoot"}else{Write-Host '[INFO] No secure backup root (normal before first patch or after Restore).'}

H 'Summary'
if($findings.Count){$findings | Format-Table Severity,Category,Item,Detail -Wrap -AutoSize | Out-Host}else{Write-Host '[OK] No findings.' -ForegroundColor Green}
$high=@($findings|Where-Object Severity -eq 'HIGH').Count
if($high -eq 0){Write-Host '[PASS] No HIGH-risk security residue detected.' -ForegroundColor Green}else{Write-Host "[FAIL] $high HIGH-risk finding(s) detected." -ForegroundColor Red}

if($ExportReport){
    $dest='C:\Users\Public\Desktop'; if(-not(Test-Path $dest)){$dest=[Environment]::GetFolderPath('Desktop')}
    $out=Join-Path $dest ("ClaudeRtlPatch-v1.3.2-Verify-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    [pscustomobject]@{Timestamp=(Get-Date).ToString('o');Package=$root;PackageOwnerSid=$rootOwner;Findings=$findings} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $out -Encoding UTF8
    Write-Host "[+] Report: $out" -ForegroundColor Green
}
