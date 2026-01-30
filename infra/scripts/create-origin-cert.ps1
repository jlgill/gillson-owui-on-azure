<#
.SYNOPSIS
    Creates a Cloudflare Origin Certificate and converts it to PFX for Azure deployment.

.DESCRIPTION
    Uses the Cloudflare API to generate an Origin Certificate, saves the cert and key,
    then creates a passwordless PFX and Base64 encodes it for use with Azure Container Apps.

.PARAMETER Token
    Your Cloudflare API Token with Origin CA permissions.

.PARAMETER Hostnames
    Array of hostnames for the certificate (e.g., "openwebui.example.com", "*.example.com")

.PARAMETER ValidityDays
    Certificate validity in days. Default is 5475 (15 years). Options: 7, 30, 90, 365, 730, 1095, 5475

.PARAMETER OutputPath
    Directory to save certificate files. Default is current directory.

.EXAMPLE
    .\create-origin-cert.ps1 -Token "your-api-token" -Hostnames @("openwebui.gillson.cloud", "*.gillson.cloud")
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Token,
    
    [Parameter(Mandatory=$true)]
    [string[]]$Hostnames,
    
    [int]$ValidityDays = 5475,
    
    [string]$OutputPath = "."
)

# Ensure OpenSSL is in PATH
$env:Path += ";C:\Program Files\OpenSSL-Win64\bin"

Write-Host "Creating Cloudflare Origin Certificate..." -ForegroundColor Cyan
Write-Host "Hostnames: $($Hostnames -join ', ')" -ForegroundColor Gray
Write-Host "Validity: $ValidityDays days" -ForegroundColor Gray

# Create the certificate request
$body = @{
    hostnames = $Hostnames
    requested_validity = $ValidityDays
    request_type = "origin-rsa"
    csr = $null
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "https://api.cloudflare.com/client/v4/certificates" `
        -Method POST `
        -Headers @{ 
            "Authorization" = "Bearer $Token"
            "Content-Type" = "application/json" 
        } `
        -Body $body

    if (-not $response.success) {
        Write-Error "Cloudflare API Error: $($response.errors | ConvertTo-Json)"
        exit 1
    }

    # Extract certificate and private key
    $cert = $response.result.certificate
    $key = $response.result.private_key
    $certId = $response.result.id

    Write-Host "✓ Certificate created successfully (ID: $certId)" -ForegroundColor Green

    # Save to files
    $certPath = Join-Path $OutputPath "origin.pem"
    $keyPath = Join-Path $OutputPath "origin.key"
    $pfxPath = Join-Path $OutputPath "cloudflare-origin.pfx"

    $cert | Out-File -FilePath $certPath -Encoding ASCII -NoNewline
    $key | Out-File -FilePath $keyPath -Encoding ASCII -NoNewline

    Write-Host "✓ Saved certificate to: $certPath" -ForegroundColor Green
    Write-Host "✓ Saved private key to: $keyPath" -ForegroundColor Green

    # Create PFX
    Write-Host "Creating PFX file..." -ForegroundColor Cyan
    & openssl pkcs12 -export -out $pfxPath -inkey $keyPath -in $certPath -password pass:

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create PFX file. Ensure OpenSSL is installed."
        exit 1
    }

    Write-Host "✓ Created PFX file: $pfxPath" -ForegroundColor Green

    # Base64 encode
    $pfxBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pfxPath))

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "SUCCESS! Certificate ready for deployment" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "PFX Base64 string saved to variable. Use it like this:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host 'az deployment sub create `' -ForegroundColor White
    Write-Host '  --location westus2 `' -ForegroundColor White
    Write-Host '  --template-file infra/bicep/app.bicep `' -ForegroundColor White
    Write-Host '  --parameters infra/bicep/app.bicepparam `' -ForegroundColor White
    Write-Host '  --parameters parCertificatePfxBase64="<base64-string>" `' -ForegroundColor White
    Write-Host '  --parameters parPostgresAdminPassword="<YourPassword>"' -ForegroundColor White
    Write-Host ""

    # Return the base64 string
    return $pfxBase64

} catch {
    Write-Error "Failed to create certificate: $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Error "Response: $responseBody"
    }
    exit 1
}
