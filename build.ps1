#Requires -Version 5.1
param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Debug"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dotnet = "C:\Program Files\dotnet\dotnet.exe"
if (-not (Test-Path $dotnet)) { $dotnet = "dotnet" }
$project = Join-Path $root "Qalculate\Qalculate.csproj"

Write-Host "Bundling qalc runtime..." -ForegroundColor Cyan
& (Join-Path $root "scripts\bundle-qalc.ps1")
if ($LASTEXITCODE -ne 0) { throw "bundle-qalc.ps1 failed" }

Write-Host "Generating icon assets..." -ForegroundColor Cyan
& (Join-Path $root "scripts\generate-icons.ps1")
if ($LASTEXITCODE -ne 0) { throw "generate-icons.ps1 failed" }

if ($Configuration -eq "Release") {
    & (Join-Path $root "scripts\build-msix.ps1") -SkipBundle
    if ($LASTEXITCODE -ne 0) { throw "build-msix.ps1 failed" }
    return
}

Write-Host "Ensuring dev signing certificate..." -ForegroundColor Cyan
& (Join-Path $root "scripts\ensure-dev-cert.ps1")
if ($LASTEXITCODE -ne 0) { throw "ensure-dev-cert.ps1 failed" }

Write-Host "Building Debug x64 MSIX..." -ForegroundColor Cyan
& $dotnet build $project -c Debug -p:Platform=x64 -p:RuntimeIdentifier=win-x64 -p:GenerateAppxPackageOnBuild=true
if ($LASTEXITCODE -ne 0) { throw "Debug MSIX build failed" }

Write-Host "Build complete." -ForegroundColor Green
