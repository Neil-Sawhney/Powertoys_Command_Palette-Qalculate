#Requires -Version 5.1
<#
.SYNOPSIS
    Copies a working qalc CLI runtime into Qalculate/qalc for bundling in the MSIX.
.DESCRIPTION
    Qalculate needs qalc.exe plus many DLLs and the definitions/ folder (~160 MB).
    Release builds require this bundle — run manually or via build.ps1 / test.ps1.
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
        "${env:ProgramFiles}\Qalculate",
        "${env:ProgramFiles(x86)}\Qalculate",
        (scoop prefix qalculate 2>$null)
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
    # Exclude GUI apps, user data, and paths that break MSIX packaging (PRI errors).
    $exclude = @(
        "qalculate-gtk.exe", "qalculate-qt.exe", "gnuplot.exe", "gdbus.exe",
        "doc", "locale", "pixmaps", "translations", "user", "licenses", "share"
    )
    Get-ChildItem $Source | Where-Object { $exclude -notcontains $_.Name } | ForEach-Object {
        Copy-Item $_.FullName -Destination $dest -Recurse -Force
    }
}

# GPL: ship a minimal license notice (full dependency license trees break MSIX PRI indexing).
$licensesDest = Join-Path $dest "licenses"
New-Item -ItemType Directory -Path $licensesDest -Force | Out-Null
foreach ($licenseFile in @("COPYING", "LICENSE", "LICENSE.txt", "COPYING.txt")) {
    $licensePath = Join-Path $Source $licenseFile
    if (Test-Path $licensePath) {
        Copy-Item $licensePath $licensesDest -Force
    }
}
$gplSrc = Join-Path $Source "licenses\GPL-2.0.txt"
if (Test-Path $gplSrc) {
    Copy-Item $gplSrc $licensesDest -Force
}

@"
Qalculate CLI (qalc) — Third-Party Notice
=========================================

This extension bundles the Qalculate command-line tool (qalc).
Qalculate is licensed under the GNU General Public License v2.0.
Full license texts are in the licenses/ folder next to qalc.exe.

Upstream: https://qalculate.github.io/
Source code: https://github.com/Qalculate/libqalculate

The PowerQalc Command Palette extension code is licensed under the MIT License (see LICENSE in the repo root).
"@ | Set-Content -Path (Join-Path $dest "ThirdPartyNotices.txt") -Encoding UTF8

$sizeMb = [math]::Round((Get-ChildItem $dest -Recurse -File | Measure-Object Length -Sum).Sum / 1MB, 1)
Write-Host "Bundled qalc runtime ($sizeMb MB). Rebuild the extension to include it in the MSIX."

$test = Start-Process -FilePath (Join-Path $dest "qalc.exe") -ArgumentList '-t','2+2' -WorkingDirectory $dest -Wait -PassThru -NoNewWindow
if ($test.ExitCode -ne 0) {
    Write-Warning "Bundled qalc test failed (exit $($test.ExitCode)). Try without -Minimal."
}
else {
    Write-Host "Bundled qalc self-test passed (2+2)." -ForegroundColor Green
}
