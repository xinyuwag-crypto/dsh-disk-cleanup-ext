#requires -Version 7.0
<#
.SYNOPSIS
    Draws store artwork: the 440x280 small promo tile (and a 1280x800 feature card).
.NOTES
    These are promotional graphics, not screenshots. The Web Store screenshot slots still need
    captures from the running extension.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$outDir = Join-Path $root 'store'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

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

function Draw-Icon($g, [float]$x, [float]$y, [float]$size) {
    $pad = $size * 0.06
    $body = $size - $pad * 2
    $path = New-RoundedPath $x $pad $body $body ($size * 0.22)
    $bg = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#4167C8'))
    $g.FillPath($bg, $path)
    $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    $g.FillRectangle($white, [float]($x + $size * 0.22), [float]($size * 0.52), [float]($size * 0.44), [float]($size * 0.10))
    $dot = $size * 0.055
    $g.FillEllipse($white, [float]($x + $size * 0.22), [float]($size * 0.38), [float]$dot, [float]$dot)
    $green = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#7DEFB6'))
    $cx = $x + $size * 0.70; $cy = $size * 0.30
    $arm = $size * 0.13; $thin = $size * 0.035
    $pts = @(
        [System.Drawing.PointF]::new($cx, $cy - $arm), [System.Drawing.PointF]::new($cx + $thin, $cy - $thin),
        [System.Drawing.PointF]::new($cx + $arm, $cy), [System.Drawing.PointF]::new($cx + $thin, $cy + $thin),
        [System.Drawing.PointF]::new($cx, $cy + $arm), [System.Drawing.PointF]::new($cx - $thin, $cy + $thin),
        [System.Drawing.PointF]::new($cx - $arm, $cy), [System.Drawing.PointF]::new($cx - $thin, $cy - $thin)
    )
    $g.FillPolygon($green, $pts)
}

function Draw-FitText($g, [string]$text, [string]$family, [float]$size, $style, $brush, [float]$x, [float]$y, [float]$maxWidth) {
    $font = New-Object System.Drawing.Font($family, $size, $style)
    while ($size -gt 6) {
        $width = $g.MeasureString($text, $font).Width
        if ($width -le $maxWidth) { break }
        $font.Dispose()
        $size -= 0.5
        $font = New-Object System.Drawing.Font($family, $size, $style)
    }
    $g.DrawString($text, $font, $brush, $x, $y)
    $font.Dispose()
}

# ---------------------------------------------------------------- 440 x 280 promo tile
$tile = New-Object System.Drawing.Bitmap 440, 280
$g = [System.Drawing.Graphics]::FromImage($tile)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.Point]::new(0, 0), [System.Drawing.Point]::new(440, 280),
    [System.Drawing.ColorTranslator]::FromHtml('#1E2A44'), [System.Drawing.ColorTranslator]::FromHtml('#0F1622'))
$g.FillRectangle($bgBrush, 0, 0, 440, 280)

Draw-Icon $g 24 30 72

$whiteBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$mutedBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#A8B4C8'))
$accentBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#7DEFB6'))

Draw-FitText $g 'DSH Disk Cleanup' 'Segoe UI Semibold' 22 ([System.Drawing.FontStyle]::Bold) $whiteBrush 108 34 308
Draw-FitText $g '磁盘清理 · 本地报告 + 浏览器数据' 'Microsoft YaHei UI' 10.5 ([System.Drawing.FontStyle]::Regular) $mutedBrush 110 68 306

Draw-FitText $g '· 存储结构：目录、大文件、类型分布' 'Microsoft YaHei UI' 11 ([System.Drawing.FontStyle]::Regular) $whiteBrush 26 132 392
Draw-FitText $g '· 清理建议：可清理 / 需确认 / 勿动' 'Microsoft YaHei UI' 11 ([System.Drawing.FontStyle]::Regular) $whiteBrush 26 164 392
Draw-FitText $g '· 一键清除浏览器缓存、站点数据与历史' 'Microsoft YaHei UI' 11 ([System.Drawing.FontStyle]::Regular) $whiteBrush 26 196 392

$g.FillRectangle($accentBrush, 26, 236, 64, 4)

$tilePath = Join-Path $outDir 'promo-440x280.png'
$tile.Save($tilePath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $tile.Dispose()
Write-Host ("promo tile -> {0} ({1:N0} bytes)" -f $tilePath, (Get-Item $tilePath).Length)

# ---------------------------------------------------------------- 1280 x 800 feature card
$card = New-Object System.Drawing.Bitmap 1280, 800
$g = [System.Drawing.Graphics]::FromImage($card)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

$cardBg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.Point]::new(0, 0), [System.Drawing.Point]::new(1280, 800),
    [System.Drawing.ColorTranslator]::FromHtml('#22304F'), [System.Drawing.ColorTranslator]::FromHtml('#0D131C'))
$g.FillRectangle($cardBg, 0, 0, 1280, 800)

Draw-Icon $g 96 96 160

$bigFont = New-Object System.Drawing.Font('Segoe UI Semibold', 52, [System.Drawing.FontStyle]::Bold)
$midFont = New-Object System.Drawing.Font('Microsoft YaHei UI', 20)
$g.DrawString('DSH Disk Cleanup', $bigFont, $whiteBrush, [float]300, [float]110)
$g.DrawString('把本机清理结果放进浏览器', $midFont, $mutedBrush, [float]304, [float]200)

$lines = @(
    '· 存储结构：目录占用、最大文件、类型分布',
    '· 清理建议：可清理 / 需确认 / 勿动 三档',
    '· 一键清除浏览器缓存、站点数据、历史',
    '· 全部本机处理，不上传任何数据'
)
$y = 300
foreach ($line in $lines) {
    $g.DrawString($line, $midFont, $whiteBrush, [float]104, [float]$y)
    $y += 64
}
$g.DrawString('需要配套桌面端：DSH 清理插件', $midFont, $accentBrush, [float]104, [float]660)

$cardPath = Join-Path $outDir 'feature-1280x800.png'
$card.Save($cardPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $card.Dispose()
Write-Host ("feature card -> {0} ({1:N0} bytes)" -f $cardPath, (Get-Item $cardPath).Length)
