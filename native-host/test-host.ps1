#requires -Version 7.0
<#
.SYNOPSIS
    Smoke-tests the native messaging host over the real stdio framing protocol.
.EXAMPLE
    pwsh -File test-host.ps1
#>
[CmdletBinding()]
param([string]$Exe)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSCommandPath
if (-not $Exe) { $Exe = Join-Path (Split-Path -Parent $here) 'dist\dsh-cleanup-host.exe' }
if (-not (Test-Path -LiteralPath $Exe)) { throw "host exe not found: $Exe" }

function Send-Frame {
    param($Process, [string]$Json)
    $body = [System.Text.Encoding]::UTF8.GetBytes($Json)
    $head = [BitConverter]::GetBytes([int]$body.Length)
    $stdin = $Process.StandardInput.BaseStream
    $stdin.Write($head, 0, 4)
    $stdin.Write($body, 0, $body.Length)
    $stdin.Flush()
}

function Read-Frame {
    param($Process)
    $stdout = $Process.StandardOutput.BaseStream
    $head = New-Object byte[] 4
    $read = 0
    while ($read -lt 4) {
        $n = $stdout.Read($head, $read, 4 - $read)
        if ($n -le 0) { return $null }
        $read += $n
    }
    $len = [BitConverter]::ToInt32($head, 0)
    $body = New-Object byte[] $len
    $read = 0
    while ($read -lt $len) {
        $n = $stdout.Read($body, $read, $len - $read)
        if ($n -le 0) { return $null }
        $read += $n
    }
    return [System.Text.Encoding]::UTF8.GetString($body)
}

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $Exe
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$process = [System.Diagnostics.Process]::Start($psi)

$cases = @(
    @{ Id = '1'; Action = 'ping' },
    @{ Id = '2'; Action = 'structure' },
    @{ Id = '3'; Action = 'status' },
    @{ Id = '4'; Action = 'nope' }
)

$results = @()
foreach ($case in $cases) {
    Send-Frame $process (@{ id = $case.Id; action = $case.Action } | ConvertTo-Json -Compress)
    $raw = Read-Frame $process
    if (-not $raw) { $results += "case $($case.Action): NO RESPONSE"; continue }
    try {
        $parsed = $raw | ConvertFrom-Json
        $shape = if ($parsed.ok) { 'ok' } else { 'error' }
        $detail = if ($case.Action -eq 'ping') { $parsed.data.host }
                  elseif ($case.Action -eq 'structure') { '{0} dirs' -f @($parsed.data.TopDirs).Count }
                  elseif ($case.Action -eq 'status') { 'mode=' + $parsed.data.Mode }
                  else { $parsed.data.error }
        $results += "case {0,-9} id={1} {2}  {3}" -f $case.Action, $parsed.id, $shape, $detail
    } catch {
        $results += "case $($case.Action): invalid JSON -> " + $raw.Substring(0, [Math]::Min(120, $raw.Length))
    }
}

Send-Frame $process '{"id":"9","action":"quit"}'
$null = Read-Frame $process
$process.StandardInput.Close()
$process.WaitForExit(5000) | Out-Null

$results | ForEach-Object { Write-Host $_ }
if ($process.HasExited) { Write-Host ("exit code: {0}" -f $process.ExitCode) }
