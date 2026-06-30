#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

& (Join-Path $root "build.ps1")
if ($LASTEXITCODE -ne 0) { throw "build.ps1 failed" }

& (Join-Path $root "scripts\install-debug-msix.ps1") -Force

Write-Host ""
Write-Host "Installed. Open Command Palette and run: Reload"
Write-Host "Then search for 'PowerQalc' and try: 5 miles + 10 km, 10 mph * x = 20 mi to min, 240 * 15%, 1 ly to km"
Write-Host ""
Write-Host "This was a local test install (Debug, dev-signed)." -ForegroundColor DarkGray
Write-Host "When you are ready to publish, run:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -Configuration Release" -ForegroundColor Yellow
Write-Host "Then upload Qalculate\AppPackages\PowerQalc_1.0.0.0.msixbundle to Partner Center."
