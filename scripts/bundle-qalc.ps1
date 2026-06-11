#Requires -Version 5.1
<#
.SYNOPSIS
    Copies a working qalc CLI runtime into Qalculate/qalc for optional bundling in the MSIX.
.DESCRIPTION
    Qalculate needs qalc.exe plus many DLLs and the definitions/ folder (~160 MB from Scoop).
    This script copies a local Qalculate install into the extension project.
    Alternatively, use the WinGet dependency on qalculate.qalculate (recommended for publishing).
.PARAMETER Source
    Path to a Qalculate install root that contains qalc.exe (Scoop, winget, or manual install).
.PARAMETER Minimal
    Copy only qalc.exe, libqalculate, definitions, and required DLLs (may miss dependencies on some systems).
#>
param(
    [string]$Source = "",
    [switch]$Minimal
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$dest = Join-Path $projectRoot "Qalculate\qalc"

if ([string]::IsNullOrWhiteSpace($Source)) {
    $candidates = @(
        (scoop prefix qalculate 2>$null),
        "${env:ProgramFiles}\Qalculate",
        "${env:ProgramFiles(x86)}\Qalculate"
    ) | Where-Object { $_ -and (Test-Path (Join-Path $_ "qalc.exe")) }

    if ($candidates.Count -eq 0) {
        Write-Error "Could not find qalc.exe. Install with: winget install qalculate.qalculate`nThen rerun: .\scripts\bundle-qalc.ps1"
    }

    $Source = $candidates[0]
}

$Source = (Resolve-Path $Source).Path
Write-Host "Source: $Source"
Write-Host "Destination: $dest"

if (Test-Path $dest) {
    Remove-Item $dest -Recurse -Force
}

New-Item -ItemType Directory -Path $dest | Out-Null

if ($Minimal) {
    Copy-Item (Join-Path $Source "qalc.exe") $dest
    Copy-Item (Join-Path $Source "libqalculate-*.dll") $dest
    Copy-Item (Join-Path $Source "definitions") $dest -Recurse
    Get-ChildItem $Source -Filter "*.dll" | Copy-Item -Destination $dest
    Write-Warning "Minimal bundle may be missing DLLs. Test with: Qalculate\qalc\qalc.exe -t `"2+2`""
}
else {
    $exclude = @("qalculate-gtk.exe", "qalculate-qt.exe", "gnuplot.exe", "gdbus.exe", "doc", "licenses", "locale", "pixmaps", "translations", "user")
    Get-ChildItem $Source | Where-Object { $exclude -notcontains $_.Name } | ForEach-Object {
        Copy-Item $_.FullName -Destination $dest -Recurse -Force
    }
}

$sizeMb = [math]::Round((Get-ChildItem $dest -Recurse -File | Measure-Object Length -Sum).Sum / 1MB, 1)
Write-Host "Bundled qalc runtime ($sizeMb MB). Rebuild the extension to include it in the MSIX."

$test = Start-Process -FilePath (Join-Path $dest "qalc.exe") -ArgumentList '-t','2+2' -WorkingDirectory $dest -Wait -PassThru -NoNewWindow
if ($test.ExitCode -ne 0) {
    Write-Warning "Bundled qalc test failed (exit $($test.ExitCode)). Try without -Minimal or use WinGet dependency instead."
}
