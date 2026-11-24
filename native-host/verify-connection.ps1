#requires -Version 7.0
<#
.SYNOPSIS
    Verifies the native messaging chain end to end and prints PASS/FAIL per check.
.DESCRIPTION
    Checks the compiled host, its manifest, the HKCU registration for Chrome and Edge, the
    allowed_origins id, and finally speaks the framing protocol to the host.
.PARAMETER ExtensionId
    Expected extension id. Defaults to the id recorded in the host manifest.
.EXAMPLE
    pwsh -File native-host\verify-connection.ps1
    pwsh -File native-host\verify-connection.ps1 -ExtensionId abcdefghijklmnopabcdefghijklmnop
#>
[CmdletBinding()]
param([string]$ExtensionId)

$ErrorActionPreference = 'Stop'
$hostDir = Split-Path -Parent $PSCommandPath
$root = Split-Path -Parent $hostDir
$dist = Join-Path $root 'dist'
$exe = Join-Path $dist 'dsh-cleanup-host.exe'
$manifestPath = Join-Path $dist 'com.dsh.disk_cleanup.json'
$hostName = 'com.dsh.disk_cleanup'

$results = New-Object System.Collections.Generic.List[object]
function Check([string]$Name, [scriptblock]$Test) {
    try {
        $detail = & $Test
        $results.Add([pscustomobject]@{ Check = $Name; Ok = $true; Detail = "$detail" })
    } catch {
        $results.Add([pscustomobject]@{ Check = $Name; Ok = $false; Detail = $_.Exception.Message })
    }
}

Check 'host exe exists' {
    if (-not (Test-Path -LiteralPath $exe)) { throw "missing: $exe" }
    '{0:N0} bytes' -f (Get-Item $exe).Length
}

Check 'host manifest parses' {
    if (-not (Test-Path -LiteralPath $manifestPath)) { throw "missing: $manifestPath" }
    $script:manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding utf8 | ConvertFrom-Json
    'name=' + $script:manifest.name
}

Check 'manifest path matches exe' {
    if ($script:manifest.path -ne $exe) { throw "manifest points to $($script:manifest.path)" }
    'ok'
}

$expected = if ($ExtensionId) { $ExtensionId } else {
    if ($script:manifest -and $script:manifest.allowed_origins) {
        ($script:manifest.allowed_origins[0] -replace '^chrome-extension://', '') -replace '/$', ''
    }
}

Check 'allowed_origins matches extension id' {
    if (-not $expected) { throw 'no extension id supplied and none recorded in the manifest' }
    if (-not ($script:manifest.allowed_origins -contains "chrome-extension://$expected/")) {
        throw "manifest allows $($script:manifest.allowed_origins -join ',')"
    }
    "chrome-extension://$expected/"
}

foreach ($browser in 'Chrome', 'Edge') {
    Check "$browser registry" {
        $key = "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$hostName"
        if ($browser -eq 'Edge') { $key = "HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\$hostName" }
        $value = (Get-ItemProperty -Path $key -ErrorAction Stop).'(default)'
        if ($value -ne $manifestPath) { throw "points to $value" }
        'ok'
    }
}

Check 'protocol ping' {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $process = [System.Diagnostics.Process]::Start($psi)

    $body = [System.Text.Encoding]::UTF8.GetBytes('{"id":"1","action":"ping"}')
    $stdin = $process.StandardInput.BaseStream
    $stdin.Write([BitConverter]::GetBytes([int]$body.Length), 0, 4)
    $stdin.Write($body, 0, $body.Length)
    $stdin.Flush()

    $head = New-Object byte[] 4
    $read = 0
    while ($read -lt 4) { $n = $process.StandardOutput.BaseStream.Read($head, $read, 4 - $read); if ($n -le 0) { break }; $read += $n }
    if ($read -lt 4) { throw 'no response from host' }
    $len = [BitConverter]::ToInt32($head, 0)
    $buffer = New-Object byte[] $len
    $read = 0
    while ($read -lt $len) { $n = $process.StandardOutput.BaseStream.Read($buffer, $read, $len - $read); if ($n -le 0) { break }; $read += $n }

    $reply = [System.Text.Encoding]::UTF8.GetString($buffer) | ConvertFrom-Json
    $stdin.Close()
    if (-not $process.WaitForExit(3000)) { $process.Kill() }
    if (-not $reply.ok) { throw "host replied with error: $($reply.data.error)" }
    'host=' + $reply.data.host
}

Write-Host ''
Write-Host 'DSH Disk Cleanup - connection check'
Write-Host ('extension id: {0}' -f $expected)
Write-Host ''
foreach ($r in $results) {
    $mark = if ($r.Ok) { 'PASS' } else { 'FAIL' }
    Write-Host ('  [{0}] {1,-34} {2}' -f $mark, $r.Check, $r.Detail)
}
$failed = @($results | Where-Object { -not $_.Ok }).Count
Write-Host ''
if ($failed -gt 0) {
    Write-Host ("{0} check(s) failed. Fix the FAIL lines above." -f $failed) -ForegroundColor Yellow
    exit 1
}
Write-Host 'All checks passed. Reload the extension, then open its popup.' -ForegroundColor Green
