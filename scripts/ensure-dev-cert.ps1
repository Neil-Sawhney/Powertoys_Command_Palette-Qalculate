#Requires -Version 5.1
<#
.SYNOPSIS
    Ensures a local code-signing certificate exists for Debug MSIX sideloading.
#>
param(
    [string]$ProjectDir = (Join-Path (Split-Path -Parent $PSScriptRoot) "Qalculate"),
    [string]$Subject = "CN=Neil Sawhney",
    [string]$Password = "qalculate"
)

$ErrorActionPreference = "Stop"

$pfxPath = Join-Path $ProjectDir "Qalculate_TemporaryKey.pfx"
$cerPath = Join-Path $ProjectDir "Qalculate_TemporaryKey.cer"
$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force

function Test-ExistingDevCert {
    if (-not (Test-Path $pfxPath)) {
        return $false
    }

    try {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
            $pfxPath, $Password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
        $valid = ($cert.Subject -eq $Subject) -and ($cert.NotAfter -gt (Get-Date).AddDays(7))
        $cert.Dispose()
        return $valid
    }
    catch {
        return $false
    }
}

if (Test-ExistingDevCert) {
    Write-Host "Dev signing certificate already present: $pfxPath" -ForegroundColor DarkGray
    Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\CurrentUser\My -Password $securePassword | Out-Null
    return
}

Write-Host "Creating local dev signing certificate ($Subject)..." -ForegroundColor Cyan

$existing = Get-ChildItem Cert:\CurrentUser\My -ErrorAction SilentlyContinue |
    Where-Object { $_.Subject -eq $Subject -and $_.NotAfter -gt (Get-Date).AddDays(7) } |
    Sort-Object NotAfter -Descending |
    Select-Object -First 1

if (-not $existing) {
    $existing = New-SelfSignedCertificate `
        -Type Custom `
        -Subject $Subject `
        -KeyUsage DigitalSignature `
        -FriendlyName "PowerQalc Dev Package Signing" `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")
}

if (Test-Path $pfxPath) {
    Remove-Item $pfxPath -Force
}
if (Test-Path $cerPath) {
    Remove-Item $cerPath -Force
}

Export-PfxCertificate -Cert $existing -FilePath $pfxPath -Password $securePassword | Out-Null
Export-Certificate -Cert $existing -FilePath $cerPath | Out-Null

Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\CurrentUser\My -Password $securePassword | Out-Null

Write-Host "Dev certificate written:" -ForegroundColor Green
Write-Host "  $pfxPath"
Write-Host "  $cerPath"
