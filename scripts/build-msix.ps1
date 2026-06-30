#Requires -Version 5.1
<#
.SYNOPSIS
    Bundles qalc and builds signed Release MSIX packages for x64 and ARM64.
#>
param(
    [string]$Configuration = "Release",
    [string]$Version = "1.0.0",
    [switch]$SkipBundle
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$project = Join-Path $root "Qalculate\Qalculate.csproj"
$bundleScript = Join-Path $PSScriptRoot "bundle-qalc.ps1"
$qalcExe = Join-Path $root "Qalculate\qalc\qalc.exe"
$dotnet = "C:\Program Files\dotnet\dotnet.exe"

if (-not (Test-Path $dotnet)) {
    $dotnet = "dotnet"
}

if (-not $SkipBundle) {
    Write-Host "Bundling qalc runtime..." -ForegroundColor Cyan
    & $bundleScript
    if ($LASTEXITCODE -ne 0) {
        throw "bundle-qalc.ps1 failed"
    }

    Write-Host "Generating icon assets..." -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot "generate-icons.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "generate-icons.ps1 failed"
    }
}
elseif (-not (Test-Path $qalcExe)) {
    throw "qalc is not bundled. Run without -SkipBundle or execute .\scripts\bundle-qalc.ps1"
}

foreach ($platform in @("x64", "ARM64")) {
    Write-Host "`n=== Building $platform MSIX ===" -ForegroundColor Cyan
    & $dotnet build $project `
        -c $Configuration `
        -p:Platform=$platform `
        -p:GenerateAppxPackageOnBuild=true `
        -p:AppxPackageDir="AppPackages\$platform\"

    if ($LASTEXITCODE -ne 0) {
        throw "Build failed for $platform"
    }
}

Write-Host "`nMSIX packages:" -ForegroundColor Green
$msixFiles = @(Get-ChildItem (Join-Path $root "Qalculate\AppPackages") -Recurse -Filter "*.msix" |
    Sort-Object LastWriteTime -Descending)
$msixFiles | Select-Object -First 4 | ForEach-Object { Write-Host "  $($_.FullName)" }

$x64Msix = $msixFiles | Where-Object { $_.Name -match '_x64\.msix$' } | Select-Object -First 1
$arm64Msix = $msixFiles | Where-Object { $_.Name -match '_ARM64\.msix$' } | Select-Object -First 1

if ($x64Msix -and $arm64Msix) {
    $bundlePath = Join-Path $root "Qalculate\AppPackages\PowerQalc_1.0.0.0.msixbundle"
    $mappingFile = Join-Path $env:TEMP "powerqalc_bundle_mapping.txt"
    @"
[Files]
"$($x64Msix.FullName)" "$($x64Msix.Name)"
"$($arm64Msix.FullName)" "$($arm64Msix.Name)"
"@ | Set-Content -Path $mappingFile -Encoding ASCII

    $makeappx = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\makeappx.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1

    if ($makeappx) {
        Write-Host "`nCreating MSIX bundle for Partner Center..." -ForegroundColor Cyan
        & $makeappx.FullName bundle /f $mappingFile /p $bundlePath /o
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  $bundlePath" -ForegroundColor Green
        }
        else {
            Write-Warning "makeappx bundle failed - create the .msixbundle manually before Store upload."
        }
    }
    else {
        Write-Warning "makeappx.exe not found (install Windows SDK). Create the .msixbundle manually before Store upload."
    }
}
