#requires -Version 7.0
<#
.SYNOPSIS
    Compiles the Chrome native messaging host and (optionally) registers it for Chrome/Edge.
.DESCRIPTION
    Produces dist\dsh-cleanup-host.exe plus the host manifest, then writes the
    HKCU NativeMessagingHosts registry key for Chrome and Edge.
    Chrome derives an unpacked extension id from its path, so pass -ExtensionId once the
    extension is loaded or published.
.EXAMPLE
    pwsh -File build-host.ps1 -ExtensionId abcdefghijklmnopabcdefghijklmnop
#>
[CmdletBinding()]
param(
    [string]$ExtensionId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    [switch]$NoRegister
)

$ErrorActionPreference = 'Stop'
$hostDir = Split-Path -Parent $PSCommandPath
$root    = Split-Path -Parent $hostDir
$dist    = Join-Path $root 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null

$exe = Join-Path $dist 'dsh-cleanup-host.exe'
if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe -Force }

Write-Host 'Compiling host.cs ...'
$csc = @(
    "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $csc) { throw 'csc.exe not found; install the .NET Framework C# compiler or build host.cs elsewhere' }

& $csc /nologo /target:exe "/out:$exe" (Join-Path $hostDir 'host.cs') 2>&1 | ForEach-Object { Write-Host "  $_" }
if (-not (Test-Path -LiteralPath $exe)) { throw 'compile failed: no exe produced' }
Write-Host ("  built {0} ({1:N0} bytes)" -f $exe, (Get-Item $exe).Length)

$manifest = [ordered]@{
    name            = 'com.dsh.disk_cleanup'
    description     = 'DSH Disk Cleanup native host'
    path            = $exe
    type            = 'stdio'
    allowed_origins = @("chrome-extension://$ExtensionId/")
}
$manifestPath = Join-Path $dist 'com.dsh.disk_cleanup.json'
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding utf8
Write-Host ("  manifest {0}" -f $manifestPath)

if (-not $NoRegister) {
    foreach ($browser in @(
        'HKCU:\Software\Google\Chrome\NativeMessagingHosts\com.dsh.disk_cleanup',
        'HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\com.dsh.disk_cleanup'
    )) {
        New-Item -Path $browser -Force | Out-Null
        Set-ItemProperty -Path $browser -Name '(default)' -Value $manifestPath
        Write-Host ("  registered {0}" -f $browser)
    }
}

Write-Host ''
Write-Host 'Done. Reload the extension (chrome://extensions) and open its popup.'
