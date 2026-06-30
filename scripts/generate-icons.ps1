#Requires -Version 5.1
<#
.SYNOPSIS
    Generates MSIX asset sizes and a gallery icon from the source icon.png.
#>
param(
    [string]$Source = ""
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Source)) {
    $rootIcon = Join-Path $root "icon.png"
    $galleryDefault = Join-Path $root "gallery-submission\neil-sawhney\qalculate\icon.png"
    if (Test-Path $rootIcon) {
        $Source = $rootIcon
    }
    else {
        $Source = $galleryDefault
    }
}

$assetsDir = Join-Path $root "Qalculate\Assets"
$galleryIcon = Join-Path $root "gallery-submission\neil-sawhney\qalculate\icon.png"

if (-not (Test-Path $Source)) {
    Write-Error "Source icon not found: $Source"
}

New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null

$sourcePath = (Resolve-Path $Source).Path
$loaded = [System.Drawing.Image]::FromFile($sourcePath)
$sourceImage = New-Object System.Drawing.Bitmap $loaded
$loaded.Dispose()

function Save-Bitmap {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [string]$Path
    )

    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $Bitmap.Dispose()
}

function New-ScaledBitmap {
    param(
        [System.Drawing.Image]$Image,
        [int]$Width,
        [int]$Height
    )

    $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.DrawImage($Image, 0, 0, $Width, $Height)
    $graphics.Dispose()
    return $bitmap
}

function New-WideBitmap {
    param(
        [System.Drawing.Image]$Image,
        [int]$Width,
        [int]$Height
    )

    $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $iconSize = [Math]::Min($Height, [int]($Width * 0.45))
    $x = [int](($Width - $iconSize) / 2)
    $y = [int](($Height - $iconSize) / 2)
    $graphics.DrawImage($Image, $x, $y, $iconSize, $iconSize)
    $graphics.Dispose()
    return $bitmap
}

Write-Host "Source: $Source ($($sourceImage.Width)x$($sourceImage.Height))" -ForegroundColor Cyan

$msixAssets = @(
    @{ Name = "StoreLogo.png"; Width = 50; Height = 50; Wide = $false },
    @{ Name = "Square44x44Logo.targetsize-24_altform-unplated.png"; Width = 24; Height = 24; Wide = $false },
    @{ Name = "Square44x44Logo.scale-200.png"; Width = 88; Height = 88; Wide = $false },
    @{ Name = "Square150x150Logo.scale-200.png"; Width = 300; Height = 300; Wide = $false },
    @{ Name = "LockScreenLogo.scale-200.png"; Width = 48; Height = 48; Wide = $false },
    @{ Name = "Wide310x150Logo.scale-200.png"; Width = 620; Height = 300; Wide = $true },
    @{ Name = "SplashScreen.scale-200.png"; Width = 1240; Height = 600; Wide = $true }
)

foreach ($asset in $msixAssets) {
    $outPath = Join-Path $assetsDir $asset.Name
    if ($asset.Wide) {
        $bmp = New-WideBitmap -Image $sourceImage -Width $asset.Width -Height $asset.Height
    }
    else {
        $bmp = New-ScaledBitmap -Image $sourceImage -Width $asset.Width -Height $asset.Height
    }

    Save-Bitmap -Bitmap $bmp -Path $outPath
    Write-Host "  $($asset.Name) ($($asset.Width)x$($asset.Height))"
}

# Manifest references non-scaled splash path
Copy-Item (Join-Path $assetsDir "SplashScreen.scale-200.png") (Join-Path $assetsDir "SplashScreen.png") -Force

# Gallery: 256x256, must be <= 100 KB — write via temp file in case source is gallery path
$galleryBitmap = New-ScaledBitmap -Image $sourceImage -Width 256 -Height 256
$galleryTemp = Join-Path ([System.IO.Path]::GetTempPath()) "powerqalc-gallery-icon.png"
Save-Bitmap -Bitmap $galleryBitmap -Path $galleryTemp
Copy-Item $galleryTemp $galleryIcon -Force
Remove-Item $galleryTemp -Force -ErrorAction SilentlyContinue
$gallerySizeKb = [math]::Round((Get-Item $galleryIcon).Length / 1KB, 1)
Write-Host "  gallery icon.png (256x256, ${gallerySizeKb} KB)" -ForegroundColor Green

if ((Get-Item $galleryIcon).Length -gt 100KB) {
    Write-Warning "Gallery icon exceeds 100 KB limit. Re-export with stronger PNG compression."
}

$sourceImage.Dispose()
Write-Host "Done. Assets written to Qalculate\Assets and gallery-submission." -ForegroundColor Green
