#requires -Version 7.0
<#
.SYNOPSIS
    Builds the Chrome Web Store upload zip.
.DESCRIPTION
    Zips only the runtime extension files (manifest, scripts, popup, icons).
    The native host and dev tools stay out of the package; ship them separately.
#>
[CmdletBinding()]
param([string]$OutDir)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSCommandPath
if (-not $OutDir) { $OutDir = Join-Path $root 'dist' }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$manifest = Get-Content -LiteralPath (Join-Path $root 'manifest.json') -Raw -Encoding utf8 | ConvertFrom-Json
$zip = Join-Path $OutDir ("dsh-disk-cleanup-v{0}.zip" -f $manifest.version)
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }

$include = @(
    'manifest.json'
    'background.js'
    'popup.html'
    'popup.js'
    'popup.css'
    'icons/icon16.png'
    'icons/icon32.png'
    'icons/icon48.png'
    'icons/icon128.png'
)

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($zip, 'Create')
try {
    foreach ($relative in $include) {
        $full = Join-Path $root $relative
        if (-not (Test-Path -LiteralPath $full)) { throw "missing file: $relative" }
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive, $full, ($relative -replace '\\', '/'), [System.IO.Compression.CompressionLevel]::Optimal)
        Write-Host ("  + {0}" -f $relative)
    }
} finally {
    $archive.Dispose()
}

Write-Host ''
Write-Host ("package: {0} ({1:N0} bytes, {2} files)" -f $zip, (Get-Item $zip).Length, $include.Count)
