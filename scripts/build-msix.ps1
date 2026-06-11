#Requires -Version 5.1
<#
.SYNOPSIS
    Builds signed Release MSIX packages for x64 and ARM64.
#>
param(
    [string]$Configuration = "Release",
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$project = Join-Path $root "Qalculate\Qalculate.csproj"
$dotnet = "C:\Program Files\dotnet\dotnet.exe"

if (-not (Test-Path $dotnet)) {
    $dotnet = "dotnet"
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
Get-ChildItem (Join-Path $root "Qalculate\AppPackages") -Recurse -Filter "*.msix" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 4 |
    ForEach-Object { Write-Host "  $($_.FullName)" }
