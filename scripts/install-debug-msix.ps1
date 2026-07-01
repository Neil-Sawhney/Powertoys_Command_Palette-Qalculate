#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Installs the newest signed x64 Debug MSIX for local development.
#>
param(
    [switch]$Force,
    [string]$AppPackagesDir = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$projectDir = Join-Path $root "Qalculate"
$appPackages = if ([string]::IsNullOrWhiteSpace($AppPackagesDir)) {
    Join-Path $projectDir "AppPackages"
} else {
    $AppPackagesDir
}
$cerPath = Join-Path $projectDir "Qalculate_TemporaryKey.cer"
$packageName = "neilsawhney.PowerQalc"

function Get-DebugMsixPath {
    Get-ChildItem $appPackages -Recurse -Filter "*_x64_Debug.msix" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}

function Import-DevCertificate {
    if (-not (Test-Path $cerPath)) {
        throw "Dev certificate not found: $cerPath. Run test.ps1 to create it."
    }

    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cerPath)
    $thumbprint = $cert.Thumbprint
    $cert.Dispose()

    foreach ($store in @("Cert:\LocalMachine\TrustedPeople", "Cert:\CurrentUser\TrustedPeople")) {
        $existing = Get-ChildItem $store -ErrorAction SilentlyContinue |
            Where-Object { $_.Thumbprint -eq $thumbprint }
        if (-not $existing) {
            Write-Host "Trusting dev certificate in $store..." -ForegroundColor Cyan
            Import-Certificate -FilePath $cerPath -CertStoreLocation $store | Out-Null
        }
    }
}

function Install-MsixPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MsixPath
    )

    Import-DevCertificate

    $existing = Get-AppxPackage -Name $packageName -ErrorAction SilentlyContinue
    if ($existing -and $Force) {
        Write-Host "Removing existing $packageName..." -ForegroundColor Cyan
        $existing | Remove-AppxPackage -ErrorAction Stop
    }

    Write-Host "Installing $MsixPath" -ForegroundColor Cyan
    Add-AppxPackage -Path $MsixPath -ForceApplicationShutdown -ForceUpdateFromAnyVersion -ErrorAction Stop

    $installed = Get-AppxPackage -Name $packageName -ErrorAction SilentlyContinue
    if (-not $installed) {
        throw "Add-AppxPackage completed but $packageName is not registered."
    }
}

$msixPath = Get-DebugMsixPath
if (-not $msixPath) {
    throw "Debug MSIX not found under $appPackages. Run test.ps1 from the repo root."
}

Install-MsixPackage -MsixPath $msixPath
Write-Host "Debug MSIX installed ($packageName)." -ForegroundColor Green
