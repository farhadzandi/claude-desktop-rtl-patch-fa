<#
.SYNOPSIS
    Local installer wrapper for the Persian Claude Desktop RTL patch.
.DESCRIPTION
    Runs the patch.ps1 shipped next to this file. It never downloads the upstream
    project and does not enable any scheduled auto-repatch mechanism.
#>
param(
    [Alias('ArabicScriptFont', 'PersianFont')]
    [string]$CustomFont,
    [string]$CustomFontScope
)

$ErrorActionPreference = 'Stop'
$patch = Join-Path $PSScriptRoot 'patch.ps1'
if (-not (Test-Path -LiteralPath $patch)) {
    throw "patch.ps1 was not found next to install.ps1. Extract the complete Persian package first."
}

$args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$patch)
if ($CustomFont) { $args += @('-CustomFont',$CustomFont) }
if ($CustomFontScope) { $args += @('-CustomFontScope',$CustomFontScope) }

& powershell.exe @args
exit $LASTEXITCODE
