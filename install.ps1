#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$testDir = Join-Path $root "Qalculate\AppPackages\Qalculate_0.0.1.0_x64_Debug_Test"

if (-not (Test-Path $testDir)) {
    Write-Host "MSIX not found. Building first..."
    & "C:\Program Files\dotnet\dotnet.exe" build (Join-Path $root "Qalculate.sln") -c Debug -p:Platform=x64 -p:GenerateAppxPackageOnBuild=true
}

Set-Location $testDir
& .\Install.ps1 -Force

Write-Host ""
Write-Host "Installed. Open Command Palette and run: Reload"
Write-Host "Then search for 'Qalculate' and try: 2+2"
Write-Host ""
Write-Host "To publish to the Extension Gallery, see PUBLISH.md"
