<#
.SYNOPSIS
    Verifies every distributed file against MANIFEST-SHA256.txt.
.DESCRIPTION
    READ-ONLY. Accepts both common sha256sum manifest forms:
      <hash><spaces><path>
      <hash><spaces>*<path>
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$manifest = Join-Path $root 'MANIFEST-SHA256.txt'

if (-not (Test-Path -LiteralPath $manifest)) {
    throw 'MANIFEST-SHA256.txt not found.'
}

$bad = @()
$ok = 0
$parsed = 0

foreach ($line in Get-Content -LiteralPath $manifest) {
    $trim = $line.Trim()
    if (-not $trim -or $trim.StartsWith('#')) { continue }

    if ($line -notmatch '^([0-9a-fA-F]{64})\s+\*?(.+)$') {
        $bad += "UNPARSEABLE MANIFEST LINE: $line"
        continue
    }

    $parsed++
    $expected = $matches[1].ToLowerInvariant()
    $rel = $matches[2].Trim()
    $path = Join-Path $root ($rel -replace '/', '\')

    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $bad += "MISSING: $rel"
        continue
    }

    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $expected) {
        $bad += "HASH MISMATCH: $rel"
    } else {
        $ok++
    }
}

if ($parsed -eq 0) {
    Write-Host '[FAIL] Manifest contained no valid file records.' -ForegroundColor Red
    exit 2
}

if ($bad.Count) {
    $bad | ForEach-Object { Write-Host "[FAIL] $_" -ForegroundColor Red }
    exit 1
}

Write-Host "[PASS] Verified $ok file(s) against MANIFEST-SHA256.txt" -ForegroundColor Green
exit 0
