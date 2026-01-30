<#
.SYNOPSIS
    Checks for and optionally purges soft-deleted Azure resources that may conflict with deployment.

.DESCRIPTION
    This script checks for soft-deleted resources (Key Vaults, API Management services, Cognitive Services, etc.)
    that have names matching your deployment configuration. Soft-deleted resources can block new deployments
    with the same name.

.PARAMETER ConfigPath
    Path to the shared config.bicep file to extract resource names. Defaults to ../bicep/shared/config.bicep

.PARAMETER Purge
    If specified, automatically purge conflicting soft-deleted resources instead of just listing them.

.PARAMETER Recover
    If specified, attempt to recover soft-deleted resources instead of purging them.

.EXAMPLE
    # Check for soft-deleted resources (report only)
    .\cleanup-soft-deleted.ps1

.EXAMPLE
    # Purge all conflicting soft-deleted resources
    .\cleanup-soft-deleted.ps1 -Purge

.EXAMPLE
    # Recover soft-deleted resources
    .\cleanup-soft-deleted.ps1 -Recover
#>

param(
    [string]$ConfigPath = "$PSScriptRoot\..\bicep\shared\config.bicep",
    [switch]$Purge,
    [switch]$Recover
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Soft-Deleted Resource Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Extract resource names from config.bicep
function Get-ConfigValue {
    param([string]$Content, [string]$Key)
    if ($Content -match "$Key\s*:\s*'([^']+)'") {
        return $Matches[1]
    }
    return $null
}

$configContent = Get-Content $ConfigPath -Raw
$location = Get-ConfigValue -Content $configContent -Key "location"
$apimName = Get-ConfigValue -Content $configContent -Key "apimName"
$spokeNamePrefix = Get-ConfigValue -Content $configContent -Key "spokeNamePrefix"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Location: $location"
Write-Host "  APIM Name: $apimName"
Write-Host "  Spoke Name Prefix: $spokeNamePrefix"
Write-Host ""

$foundIssues = $false

# ========== Check Key Vaults ==========
Write-Host "Checking soft-deleted Key Vaults..." -ForegroundColor Yellow
$deletedKeyVaults = az keyvault list-deleted --query "[].{name:name, location:properties.location}" -o json 2>$null | ConvertFrom-Json

if ($deletedKeyVaults) {
    foreach ($kv in $deletedKeyVaults) {
        # Check if name matches our naming patterns
        if ($kv.name -like "*$spokeNamePrefix*" -or $kv.name -like "*appgw*" -or $kv.name -like "*gillson*") {
            $foundIssues = $true
            Write-Host "  [CONFLICT] Key Vault: $($kv.name) in $($kv.location)" -ForegroundColor Red
            
            if ($Purge) {
                Write-Host "    Purging..." -ForegroundColor Magenta
                az keyvault purge --name $kv.name 2>$null
                Write-Host "    Purged successfully" -ForegroundColor Green
            }
            elseif ($Recover) {
                Write-Host "    Recovering..." -ForegroundColor Magenta
                az keyvault recover --name $kv.name 2>$null
                Write-Host "    Recovered successfully" -ForegroundColor Green
            }
        }
    }
}

if (-not $foundIssues) {
    Write-Host "  No conflicting Key Vaults found" -ForegroundColor Green
}

# ========== Check API Management ==========
Write-Host ""
Write-Host "Checking soft-deleted API Management services..." -ForegroundColor Yellow
$deletedApim = az apim deletedservice list --query "[].{name:name, location:location}" -o json 2>$null | ConvertFrom-Json
$apimIssues = $false

if ($deletedApim) {
    foreach ($apim in $deletedApim) {
        if ($apim.name -eq $apimName -or $apim.name -like "*gillson*") {
            $foundIssues = $true
            $apimIssues = $true
            Write-Host "  [CONFLICT] APIM: $($apim.name) in $($apim.location)" -ForegroundColor Red
            
            if ($Purge) {
                Write-Host "    Purging (this may take a few minutes)..." -ForegroundColor Magenta
                az apim deletedservice purge --service-name $apim.name --location $apim.location 2>$null
                Write-Host "    Purged successfully" -ForegroundColor Green
            }
            elseif ($Recover) {
                Write-Host "    Note: APIM recovery requires using 'restore: true' in Bicep deployment" -ForegroundColor Yellow
            }
        }
    }
}

if (-not $apimIssues) {
    Write-Host "  No conflicting APIM services found" -ForegroundColor Green
}

# ========== Check Cognitive Services ==========
Write-Host ""
Write-Host "Checking soft-deleted Cognitive Services..." -ForegroundColor Yellow
$deletedCogSvc = az cognitiveservices account list-deleted --query "[].{name:name, location:location}" -o json 2>$null | ConvertFrom-Json
$cogSvcIssues = $false

if ($deletedCogSvc) {
    foreach ($svc in $deletedCogSvc) {
        if ($svc.name -like "*$spokeNamePrefix*" -or $svc.name -like "*foundry*" -or $svc.name -like "*gillson*") {
            $foundIssues = $true
            $cogSvcIssues = $true
            Write-Host "  [CONFLICT] Cognitive Service: $($svc.name) in $($svc.location)" -ForegroundColor Red
            
            if ($Purge) {
                Write-Host "    Purging..." -ForegroundColor Magenta
                az cognitiveservices account purge --name $svc.name --location $svc.location --resource-group "deleted" 2>$null
                Write-Host "    Purged successfully" -ForegroundColor Green
            }
            elseif ($Recover) {
                Write-Host "    Note: Cognitive Services recovery requires manual intervention" -ForegroundColor Yellow
            }
        }
    }
}

if (-not $cogSvcIssues) {
    Write-Host "  No conflicting Cognitive Services found" -ForegroundColor Green
}

# ========== Summary ==========
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($foundIssues -and -not $Purge -and -not $Recover) {
    Write-Host "CONFLICTS FOUND - Run with -Purge or -Recover flag" -ForegroundColor Red
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\cleanup-soft-deleted.ps1 -Purge    # Permanently delete"
    Write-Host "  .\cleanup-soft-deleted.ps1 -Recover  # Attempt recovery"
    exit 1
}
elseif ($foundIssues) {
    Write-Host "Cleanup completed!" -ForegroundColor Green
}
else {
    Write-Host "No conflicts found - safe to deploy!" -ForegroundColor Green
}
Write-Host "========================================" -ForegroundColor Cyan
