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
  // Cost-effective high-volume model - best for casual conversation
  // Maximized to available quota limit (200 TPM)
  {
    name: 'gpt-4o-mini'
    model: { format: 'OpenAI', name: 'gpt-4o-mini', version: '2024-07-18' }
    sku: { name: 'GlobalStandard', capacity: 200 }
  }
  // Quality responses - quota limit: 50 TPM
  {
    name: 'gpt-4o'
    model: { format: 'OpenAI', name: 'gpt-4o', version: '2024-11-20' }
    sku: { name: 'GlobalStandard', capacity: 50 }
  }
  // Long context model (1M tokens) - quota limit: 50 TPM
  {
    name: 'gpt-4.1'
    model: { format: 'OpenAI', name: 'gpt-4.1', version: '2025-04-14' }
    sku: { name: 'GlobalStandard', capacity: 50 }
  }
  // Lightweight long context
  {
    name: 'gpt-4.1-mini'
    model: { format: 'OpenAI', name: 'gpt-4.1-mini', version: '2025-04-14' }
    sku: { name: 'GlobalStandard', capacity: 200 }
  }
  // Reasoning model - quota limit: 20 TPM (maxed out, request increase)
  {
    name: 'o3-mini'
    model: { format: 'OpenAI', name: 'o3-mini', version: '2025-01-31' }
    sku: { name: 'GlobalStandard', capacity: 20 }
  }
  // Latest generation
  {
    name: 'gpt-5-mini'
    model: { format: 'OpenAI', name: 'gpt-5-mini', version: '2025-08-07' }
    sku: { name: 'GlobalStandard', capacity: 200 }
  }
]
