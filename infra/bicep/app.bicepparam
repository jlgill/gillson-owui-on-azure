using './app.bicep'

// ========== Shared Configuration ==========
// Import shared config to ensure consistency with main.bicep
import { sharedConfig } from './shared/config.bicep'

// ========== IMPORTANT: Review shared/config.bicep first ==========
// Most configuration values are centralized there. Only override here if needed.

// ===== Core Configuration (from shared config) =====
param parLocation = sharedConfig.location
param parResourceGroupName = sharedConfig.spokeResourceGroupName
param parHubResourceGroupName = sharedConfig.hubResourceGroupName
param parHubVirtualNetworkName = sharedConfig.hubVirtualNetworkName
param parCustomDomain = sharedConfig.customDomain
param parCertificateName = sharedConfig.sslCertificateName
param parApimName = sharedConfig.apimName
param parNamePrefix = sharedConfig.spokeNamePrefix
param parTags = sharedConfig.tags

// ===== Network Configuration (from shared config) =====
param parVirtualNetworkAddressPrefix = sharedConfig.spokeVnetAddressPrefix
param parAcaSubnetAddressPrefix = sharedConfig.acaSubnetAddressPrefix

// ===== Container App IP Restrictions =====
// Allow traffic from App Gateway subnet
param parContainerAppAllowedIpAddresses = [
  sharedConfig.appGatewaySubnetAddressPrefix // App Gateway subnet
]

// ===== PostgreSQL Configuration =====
param parPostgresConfig = {
  skuName: 'Standard_B1ms'
  tier: 'Burstable'
  version: '16'
  storageSizeGB: 32
  databaseName: 'openwebui'
  adminUsername: 'pgadmin'
}

// ===== Container App Scaling =====
param parContainerAppScaleSettings = {
  minReplicas: 1
  maxReplicas: 1
}

// ===== AI Model Deployments =====
// Configure which models to deploy to Azure AI Foundry
// Set to empty array to skip AI Foundry deployment (requires Azure OpenAI access approval)
// Re-add models after getting access at https://aka.ms/oai/access
// Model retirement dates: https://learn.microsoft.com/en-us/azure/ai-foundry/openai/concepts/model-retirements
param parFoundryDeployments = [
  // Currently deployed models
  {
    name: 'gpt-4o'
    model: { format: 'OpenAI', name: 'gpt-4o', version: '2024-11-20' }
    sku: { name: 'GlobalStandard', capacity: 10 }
  }
  {
    name: 'gpt-4o-mini'
    model: { format: 'OpenAI', name: 'gpt-4o-mini', version: '2024-07-18' }
    sku: { name: 'GlobalStandard', capacity: 10 }
  }
  // GPT-4.1 family (longer support window - retires no earlier than April 2026)
  {
    name: 'gpt-4.1'
    model: { format: 'OpenAI', name: 'gpt-4.1', version: '2025-04-14' }
    sku: { name: 'GlobalStandard', capacity: 10 }
  }
  {
    name: 'gpt-4.1-mini'
    model: { format: 'OpenAI', name: 'gpt-4.1-mini', version: '2025-04-14' }
    sku: { name: 'GlobalStandard', capacity: 10 }
  }
  // Reasoning model
  {
    name: 'o3-mini'
    model: { format: 'OpenAI', name: 'o3-mini', version: '2025-01-31' }
    sku: { name: 'GlobalStandard', capacity: 10 }
  }
  // GPT-5 family (advanced reasoning)
  {
    name: 'gpt-5-mini'
    model: { format: 'OpenAI', name: 'gpt-5-mini', version: '2025-08-07' }
    sku: { name: 'GlobalStandard', capacity: 10 }
  }
]
