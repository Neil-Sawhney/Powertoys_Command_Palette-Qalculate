#Requires -Version 5.1
<#
.SYNOPSIS
    Stops running app instances and clears the debug AppPackages output folder before build.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$AppPackagesDir
)

$ErrorActionPreference = "Stop"

function Remove-DirectoryWithRetry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [int]$MaxAttempts = 5
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            return
        }
        catch {
            if ($attempt -eq $MaxAttempts) {
                throw "Could not remove '$Path'. Close File Explorer windows showing it, pause OneDrive sync, then retry. $($_.Exception.Message)"
            }

            Write-Host "  Retry $attempt/$MaxAttempts..." -ForegroundColor DarkYellow
            Start-Sleep -Seconds 1
        }
    }
}

foreach ($processName in @("PowerQalc", "qalc")) {
    Get-Process -Name $processName -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "Stopping $($processName) (pid $($_.Id))..." -ForegroundColor Cyan
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
}

if (Test-Path $AppPackagesDir) {
    Write-Host "Clearing $AppPackagesDir ..." -ForegroundColor Cyan
    Remove-DirectoryWithRetry -Path $AppPackagesDir
}

New-Item -ItemType Directory -Path $AppPackagesDir -Force | Out-Null
