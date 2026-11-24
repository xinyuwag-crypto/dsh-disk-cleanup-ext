#requires -Version 7.0
<#
.SYNOPSIS
    Composes 1280x800 store screenshots from popup captures.
.DESCRIPTION
    Places the popup capture on a padded gradient canvas with a subtle border and caption.
    Source captures stay untouched; only the composed PNG is written.
.EXAMPLE
    pwsh -File tools\make-store-screenshots.ps1 -Shots "a.png:已连接","b.png:清理完成"
#>
[CmdletBinding()]
param(
    [string[]]$Shots = @(),
    [string]$OutDir
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
if (-not $OutDir) { $OutDir = Join-Path $root 'store' }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function New-RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function ConvertTo-Shot([string]$Source, [string]$Caption, [int]$Index) {
    $image = [System.Drawing.Image]::FromFile($Source)
    $canvas = New-Object System.Drawing.Bitmap 1280, 800
    $g = [System.Drawing.Graphics]::FromImage($canvas)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        [System.Drawing.Point]::new(0, 0), [System.Drawing.Point]::new(1280, 800),
        [System.Drawing.ColorTranslator]::FromHtml('#14171D'), [System.Drawing.ColorTranslator]::FromHtml('#0E131B'))
    $g.FillRectangle($bg, 0, 0, 1280, 800)

    # Per-side crop removes the window border / stray desktop sliver from the capture.
    $insetLeft = 10; $insetTop = 12; $insetRight = 12; $insetBottom = 12
    $srcRect = New-Object System.Drawing.Rectangle $insetLeft, $insetTop,
        ($image.Width - $insetLeft - $insetRight), ($image.Height - $insetTop - $insetBottom)
    $targetH = 660
    $scale = $targetH / $srcRect.Height
    $targetW = [int]($srcRect.Width * $scale)
    $x = [int]((1280 - $targetW) / 2)
    $y = 52

    $frame = New-RoundedPath ($x - 14) ($y - 14) ($targetW + 28) ($targetH + 28) 18
    $frameBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#2A3446'))
    $g.FillPath($frameBrush, $frame)

    # Plain draw on a background that matches the popup, so rounded window corners blend in.
    $dest = New-Object System.Drawing.Rectangle $x, $y, $targetW, $targetH
    $g.DrawImage($image, $dest, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)

    if ($Caption) {
        $font = New-Object System.Drawing.Font('Microsoft YaHei UI', 20)
        $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#C7D0E0'))
        $size = $g.MeasureString($Caption, $font)
        $g.DrawString($Caption, $font, $brush, [float]((1280 - $size.Width) / 2), [float]740)
        $font.Dispose(); $brush.Dispose()
    }

    $out = Join-Path $OutDir ("screenshot-{0}.png" -f $Index)
    $canvas.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $canvas.Dispose(); $image.Dispose()
    Write-Host ("{0}  <- {1} ({2:N0} bytes)" -f $out, (Split-Path $Source -Leaf), (Get-Item $out).Length)
}

if ($Shots.Count -eq 0) {
    Write-Host 'No inputs. Usage: -Shots "C:\path\popup1.png|已连接","C:\path\popup2.png|清理完成"'
    return
}

$i = 0
foreach ($shot in $Shots) {
    $i++
    $parts = $shot.Split('|', 2)
    if (-not (Test-Path -LiteralPath $parts[0])) { Write-Warning "missing: $($parts[0])"; continue }
    $caption = if ($parts.Count -gt 1) { $parts[1] } else { '' }
    ConvertTo-Shot $parts[0] $caption $i
}




