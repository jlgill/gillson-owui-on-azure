// ========== Shared Configuration ==========
// Central configuration values shared between hub (main.bicep) and spoke (app.bicep) deployments
// This eliminates duplicate values and ensures consistency across deployments
//
// Usage in .bicepparam files:
//   using './main.bicep'
//   import { sharedConfig } from './shared/config.bicep'
//   param parLocation = sharedConfig.location
//   param parCustomDomain = sharedConfig.customDomain

// ========== IMPORTANT: Update these values for your deployment ==========

@export()
@description('Shared configuration values used by both hub and spoke deployments')
var sharedConfig = {
  // ===== Required: Update these for your environment =====
  
  // Azure region for all resources
  // Note: westus supports Azure OpenAI model deployments (westus2 does not)
  location: 'westus'
  
  // Custom domain for Open WebUI (e.g., openwebui.example.com)
  customDomain: 'openwebui.gillson.us'
  
  // APIM publisher email address - MUST be updated
  apimPublisherEmail: 'jgill@gillson.me'
  
  // APIM publisher display name
  apimPublisherName: 'James Gill'
  
  // ===== Resource Naming =====
  
  // Hub resource group name
  hubResourceGroupName: 'rg-lb-core'
  
  // Hub virtual network name
  hubVirtualNetworkName: 'vnet-lb-core'
  
  // Spoke resource group name
  spokeResourceGroupName: 'rg-owui-app'
  
  // Name prefix for spoke resources (max 14 chars)
  spokeNamePrefix: 'owui-app'
  
  // APIM instance name (must be globally unique, 3-21 chars)
  apimName: 'apim-gillson-owui'
  
  // Application Gateway name (3-21 chars)
  appGatewayName: 'appgw-gillson-owui'
  
  // ===== Network Configuration =====
  
  // Hub VNet address space
  hubVnetAddressPrefix: '10.0.0.0/24'
  
  // APIM subnet address prefix
  apimSubnetAddressPrefix: '10.0.0.0/28'
  
  // App Gateway subnet address prefix
  appGatewaySubnetAddressPrefix: '10.0.0.64/26'
  
  // Private Endpoint subnet address prefix
  peSubnetAddressPrefix: '10.0.0.128/28'
  
  // Spoke VNet address space
  spokeVnetAddressPrefix: '10.0.4.0/22'
  
  // Container Apps subnet address prefix
  acaSubnetAddressPrefix: '10.0.4.0/23'
  
  // ===== Certificate Configuration =====
  
  // Name of the SSL certificate in Key Vault
  sslCertificateName: 'cloudflare-origin-cert'
  
  // Name of the trusted root certificate secret
  trustedRootCertificateSecretName: 'cloudflare-origin-ca'
  
  // ===== SKU Configuration =====
  
  // APIM SKU (Developer for demos, Premium for production)
  apimSku: 'Developer'
  
  // Application Gateway SKU
  appGatewaySku: 'Standard_v2'
  
  // ===== Tags =====
  
  // Standard resource tags
  tags: {
    Application: 'Open WebUI'
    Environment: 'Demo'
    Owner: 'James Gil'
  }
  
  documentIntelligence: {
    model: 'prebuilt-read'
    sku: 'S0'
  }
}

// ========== Derived Names (auto-calculated) ==========
// These are computed from the base config to ensure consistency

@export()
@description('Auto-derived resource names based on shared config')
var derivedNames = {
  // Spoke VNet name (derived from spokeNamePrefix)
  spokeVirtualNetworkName: '${sharedConfig.spokeNamePrefix}-vnet'
  
  // Foundry resource name (derived from spokeNamePrefix)
  foundryName: '${sharedConfig.spokeNamePrefix}-foundry'
  
  // App Gateway subnet CIDR for Container App IP restrictions
  appGatewaySubnetCidr: sharedConfig.appGatewaySubnetAddressPrefix
}

// ========== Placeholder Markers ==========
// Used to detect when values haven't been updated after Step 2

@export()
@description('Placeholder value used to indicate a value must be updated after Step 2 deployment')
var placeholderMarker = 'REPLACE_AFTER_STEP_2'
