#requires -Version 7.0
<#
.SYNOPSIS
    Draws the extension icons (16/32/48/128) with System.Drawing.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$outDir = Join-Path (Split-Path -Parent $PSCommandPath) '..\icons'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function New-RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

foreach ($size in 16, 32, 48, 128) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    $s = [float]$size
    $pad = $s * 0.06
    $body = $s - ($pad * 2)
    $radius = [Math]::Max(1.5, $s * 0.22)

    $bgPath = New-RoundedPath $pad $pad $body $body $radius
    $bgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#4167C8'))
    $g.FillPath($bgBrush, $bgPath)

    # drive slot
    $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    $slotH = [Math]::Max(1.0, $s * 0.10)
    $slotY = $s * 0.52
    $slotX = $s * 0.22
    $slotW = $s * 0.44
    $g.FillRectangle($white, [float]$slotX, [float]$slotY, [float]$slotW, [float]$slotH)

    # indicator dot
    $dot = [Math]::Max(0.8, $s * 0.055)
    $g.FillEllipse($white, [float]($s * 0.22), [float]($s * 0.38), [float]$dot, [float]$dot)

    if ($size -ge 32) {
        # sparkle
        $green = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#7DEFB6'))
        $cx = $s * 0.70
        $cy = $s * 0.30
        $arm = $s * 0.13
        $thin = $s * 0.035
        $pts = @(
            [System.Drawing.PointF]::new($cx, $cy - $arm),
            [System.Drawing.PointF]::new($cx + $thin, $cy - $thin),
            [System.Drawing.PointF]::new($cx + $arm, $cy),
            [System.Drawing.PointF]::new($cx + $thin, $cy + $thin),
            [System.Drawing.PointF]::new($cx, $cy + $arm),
            [System.Drawing.PointF]::new($cx - $thin, $cy + $thin),
            [System.Drawing.PointF]::new($cx - $arm, $cy),
            [System.Drawing.PointF]::new($cx - $thin, $cy - $thin)
        )
        $g.FillPolygon($green, $pts)
    }

    $file = Join-Path $outDir ("icon{0}.png" -f $size)
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host ("icon {0}px -> {1} ({2:N0} bytes)" -f $size, $file, (Get-Item $file).Length)
}
