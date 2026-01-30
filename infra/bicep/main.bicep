targetScope = 'subscription'
// ms graph extensibility
extension 'br:mcr.microsoft.com/bicep/extensions/microsoftgraph/v1.0:1.0.0'

// ========== Type Imports ==========
import { TagsType } from './shared/types.bicep'
// Import placeholder marker for detecting first deployment (before Step 2 outputs are available)
import { placeholderMarker } from './shared/config.bicep'

// ========== MARK: Parameters ==========
param parLocation string
param parResourceGroupName string
@description('Name of the Application Gateway. Must be 3-21 chars for combined naming with identity suffix.')
@minLength(3)
@maxLength(21)
param parAppGatewayName string
@description('Name of the API Management instance. Must be globally unique. Consider adding a unique suffix if deployment fails due to naming conflict.')
@minLength(3)
@maxLength(21)
param parApimName string
@description('APIM publisher email - must be a valid email address, not the placeholder.')
param parApimPublisherEmail string
param parApimPublisherName string
param parVirtualNetworkName string
param parVirtualNetworkAddressPrefix string
param parApimSubnetAddressPrefix string
param parAppGatewaySubnetAddressPrefix string
param parPeSubnetAddressPrefix string
param parApimSku string
param parAppGatewaySku string
param parSpokeResourceGroupName string

@description('Name prefix used in spoke deployment. Used to auto-derive spoke resource names. Must match parNamePrefix in app.bicepparam.')
@minLength(3)
@maxLength(14)
param parSpokeNamePrefix string = 'open-webui-app'

@description('Container App FQDN from app.bicep output. Set to placeholder on first deploy, update after Step 2.')
@metadata({
  example: 'open-webui-app-aca.jollyfield-adf491b7.uksouth.azurecontainerapps.io'
})
param parContainerAppFqdn string

@description('Container App static IP from app.bicep output. Set to placeholder on first deploy, update after Step 2.')
@metadata({
  example: '10.0.4.91'
})
param parContainerAppStaticIp string

param parCustomDomain string
param parTrustedRootCertificateSecretName string
param parSslCertificateSecretName string
param parTags TagsType

@description('Entra ID App Registration ID from app.bicep output (outOpenWebUIAppId). Required for APIM token validation.')
param parOpenWebUIAppId string = ''

param parConfigureFoundry bool = false


// ========== MARK: Variables ==========
var varOpenWebUi = 'open-webui'
var varNsgRules = loadJsonContent('./shared/nsg-rules.json')
var varTrustedRootCertificateBase64 = loadTextContent('./cert/cloudflare-origin-ca.cer')
var varRoleDefinitions = {
  keyVaultSecretsUser: '4633458b-17de-408a-b874-0445c86b69e6'
}

// ========== Auto-Derived Names ==========
// These are calculated from parSpokeNamePrefix to ensure consistency with app.bicep
// No need to manually specify these - they follow the same naming convention as the spoke deployment

// Spoke VNet name follows pattern: ${parSpokeNamePrefix}-vnet
var varSpokeVirtualNetworkName = '${parSpokeNamePrefix}-vnet'

// Foundry name follows pattern: ${parSpokeNamePrefix}-foundry
var varFoundryName = '${parSpokeNamePrefix}-foundry'

// Spoke Key Vault name uses uniqueString for global uniqueness (same logic as app.bicep)
// Pattern: take('${parSpokeNamePrefix}-kv-${uniqueString}', 24)
var varSpokeUniqueSuffix = uniqueString(subscription().subscriptionId, parSpokeResourceGroupName)
var varSpokeKeyVaultName = take('${parSpokeNamePrefix}-kv-${varSpokeUniqueSuffix}', 24)

// ========== Placeholder Detection ==========
// Detect if Step 2 outputs haven't been provided yet (first hub deployment)
var varIsFirstDeployment = parContainerAppFqdn == placeholderMarker || parContainerAppStaticIp == placeholderMarker
var varContainerAppEnvDefaultDomain = !varIsFirstDeployment && !empty(parContainerAppFqdn) ? join(skip(split(parContainerAppFqdn, '.'), 1), '.') : ''
var varContainerAppName = !varIsFirstDeployment && !empty(parContainerAppFqdn) ? split(parContainerAppFqdn, '.')[0] : ''

// Reference existing Foundry in spoke to get its endpoint dynamically
// Only reference when parConfigureFoundry is true (second hub deployment)
resource resFoundryExisting 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = if (parConfigureFoundry) {
  scope: resourceGroup(parSpokeResourceGroupName)
  name: varFoundryName
}

// Public IP configurations for loop deployment
var varPublicIpConfigs = [
  {
    key: 'appgw'
    name: '${parAppGatewayName}-pip'
    dnsLabel: null
  }
  {
    key: 'apim'
    name: '${parApimName}-pip'
    dnsLabel: '${parApimName}-${uniqueString(subscription().subscriptionId, parResourceGroupName)}'
  }
]

// MARK: - Resource Group
module modResourceGroup 'br/public:avm/res/resources/resource-group:0.4.2' = {
  params: {
    name: parResourceGroupName
    location: parLocation
    tags: parTags
  }
}

// MARK: - Networking
module modNetworking 'modules/networking.bicep' = {
  scope: resourceGroup(parResourceGroupName)
  params: {
    parNamePrefix: varOpenWebUi
    parLocation: parLocation
    parVirtualNetworkName: parVirtualNetworkName
    parVirtualNetworkAddressPrefix: parVirtualNetworkAddressPrefix
    parApimSubnetAddressPrefix: parApimSubnetAddressPrefix
    parAppGatewaySubnetAddressPrefix: parAppGatewaySubnetAddressPrefix
    parPeSubnetAddressPrefix: parPeSubnetAddressPrefix
    parSpokeResourceGroupName: parSpokeResourceGroupName
    // Only pass spoke VNet name when NOT first deployment (spoke must exist for peering)
    parSpokeVirtualNetworkName: varIsFirstDeployment ? '' : varSpokeVirtualNetworkName
    parContainerAppEnvDefaultDomain: varContainerAppEnvDefaultDomain
    parContainerAppName: varContainerAppName
    parContainerAppStaticIp: varIsFirstDeployment ? '' : parContainerAppStaticIp
    parNsgRules: varNsgRules
  }
  dependsOn: [modResourceGroup]
}

// MARK: - Monitoring
module modMonitoring 'modules/monitoring.bicep' = {
  scope: resourceGroup(parResourceGroupName)
  params: {
    parLocation: parLocation
    parNamePrefix: varOpenWebUi
  }
  dependsOn: [modResourceGroup]
}

// MARK: - Security (Identities & Key Vaults)
module modSecurity 'modules/security.bicep' = {
  scope: resourceGroup(parResourceGroupName)
  params: {
    parLocation: parLocation
    parAppGatewayName: parAppGatewayName
    parTrustedRootCertificateSecretName: parTrustedRootCertificateSecretName
    parTrustedRootCertificateBase64: varTrustedRootCertificateBase64
    parCustomDomain: parCustomDomain
  }
  dependsOn: [modResourceGroup]
}

// MARK: - RBAC for Spoke Key Vault
// Uses auto-derived Key Vault name based on parSpokeNamePrefix
// Only creates RBAC after spoke exists (not on first deployment)
module modAppGatewaySpokeKeyVaultRbac 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (!empty(parCustomDomain) && !varIsFirstDeployment) {
  scope: resourceGroup(parSpokeResourceGroupName)
  params: {
    principalId: modSecurity.outputs.userAssignedIdentityPrincipalId
    resourceId: resourceId(subscription().subscriptionId, parSpokeResourceGroupName, 'Microsoft.KeyVault/vaults', varSpokeKeyVaultName)
    roleDefinitionId: varRoleDefinitions.keyVaultSecretsUser
  }
}

// MARK: - Public IP Addresses
module modPublicIps 'br/public:avm/res/network/public-ip-address:0.8.0' = [for config in varPublicIpConfigs: {
  scope: resourceGroup(parResourceGroupName)
  name: 'pip-${config.key}'
  params: {
    name: config.name
    location: parLocation
    skuName: 'Standard'
    publicIPAllocationMethod: 'Static'
    zones: []
    dnsSettings: config.dnsLabel != null ? {
      domainNameLabel: config.dnsLabel!
    } : null
  }
  dependsOn: [modResourceGroup]
}]

// MARK: - Application Gateway
// Only fully configure when spoke exists (not first deployment)
module modAppGateway 'modules/app-gateway.bicep' = {
  scope: resourceGroup(parResourceGroupName)
  params: {
    parAppGatewayName: parAppGatewayName
    parLocation: parLocation
    parSku: parAppGatewaySku
    parContainerAppFqdn: varIsFirstDeployment ? '' : parContainerAppFqdn
    parCustomDomain: parCustomDomain
    // Only pass spoke Key Vault name when NOT first deployment (spoke must exist for SSL cert)
    parSpokeKeyVaultName: varIsFirstDeployment ? '' : varSpokeKeyVaultName
    parTrustedRootCertificateSecretName: parTrustedRootCertificateSecretName
    parSslCertificateSecretName: parSslCertificateSecretName
    parAppGatewaySubnetId: modNetworking.outputs.appGatewaySubnetResourceId
    parPublicIpResourceId: modPublicIps[0].outputs.resourceId
    parUserAssignedIdentityResourceId: modSecurity.outputs.userAssignedIdentityResourceId
    parHubKeyVaultUri: modSecurity.outputs.hubKeyVaultUri
    parResourceGroupName: parResourceGroupName
  }
  dependsOn: [
    modResourceGroup
  ]
}

// MARK: - API Management
module modApim 'modules/apim.bicep' = {
  scope: resourceGroup(parResourceGroupName)
  params: {
    parApimName: parApimName
    parLocation: parLocation
    parSku: parApimSku
    parPublisherEmail: parApimPublisherEmail
    parPublisherName: parApimPublisherName
    parFoundryEndpoint: parConfigureFoundry ? resFoundryExisting!.properties.endpoint : ''
    parOpenWebUIAppId: !empty(parOpenWebUIAppId) ? parOpenWebUIAppId : ''
    parAppInsightsName: modMonitoring.outputs.appInsightsName
    parAppInsightsResourceId: modMonitoring.outputs.appInsightsResourceId
    parAppInsightsConnectionString: modMonitoring.outputs.appInsightsConnectionString
    parLogAnalyticsWorkspaceResourceId: modMonitoring.outputs.logAnalyticsWorkspaceResourceId
    parApimSubnetResourceId: modNetworking.outputs.apimSubnetResourceId
    parApimPublicIpResourceId: modPublicIps[1].outputs.resourceId
  }
  dependsOn: [
    modResourceGroup
  ]
}

// MARK: - APIM → Foundry RBAC
// Grant APIM managed identity access to Foundry (Cognitive Services User + Azure AI User)
// Only configure when parConfigureFoundry is true (second hub deployment)
module modApimFoundryCognitiveServicesUserRbac 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (parConfigureFoundry) {
  scope: resourceGroup(parSpokeResourceGroupName)
  params: {
    principalId: modApim.outputs.systemAssignedMIPrincipalId
    resourceId: resFoundryExisting!.id
    roleDefinitionId: 'a97b65f3-24c7-4388-baec-2e87135dc908' // Cognitive Services User
    principalType: 'ServicePrincipal'
  }
}

module modApimFoundryAzureAIUserRbac 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (parConfigureFoundry) {
  scope: resourceGroup(parSpokeResourceGroupName)
  params: {
    principalId: modApim.outputs.systemAssignedMIPrincipalId
    resourceId: resFoundryExisting!.id
    roleDefinitionId: '53ca6127-db72-4b80-b1b0-d745d6d5456d' // Azure AI User
    principalType: 'ServicePrincipal'
  }
}

// MARK: - APIM Private DNS A Record
// Uses the private IP from the APIM module output

module modApimDnsRecord 'br/public:avm/res/network/private-dns-zone:0.8.0' = {
  scope: resourceGroup(parResourceGroupName)
  params: {
    name: modNetworking.outputs.apimPrivateDnsZoneName
    location: 'global'
    a: [
      {
        name: parApimName
        ttl: 3600
        aRecords: [
          { ipv4Address: modApim.outputs.privateIpAddress }
        ]
      }
    ]
  }
}

// MARK: - Outputs
output outApimName string = modApim.outputs.name
output outApimResourceId string = modApim.outputs.resourceId
output outApimGatewayUrl string = modApim.outputs.gatewayUrl
output outApimSystemAssignedPrincipalId string = modApim.outputs.systemAssignedMIPrincipalId
output outAppInsightsConnectionString string = modMonitoring.outputs.appInsightsConnectionString
output outAppInsightsResourceId string = modMonitoring.outputs.appInsightsResourceId
output outAppGatewayPublicIp string = modPublicIps[0].outputs.ipAddress
output outAppGatewayPublicIpResourceId string = modPublicIps[0].outputs.resourceId
output outApimPublicIp string = modPublicIps[1].outputs.ipAddress
output outVirtualNetworkResourceId string = modNetworking.outputs.virtualNetworkResourceId
output outVirtualNetworkName string = modNetworking.outputs.virtualNetworkName
output outContainerAppFqdn string = parContainerAppFqdn

// ========== Deployment Summary ==========
// Provides helpful information about what was deployed and next steps

output outDeploymentSummary object = {
  deploymentType: varIsFirstDeployment ? 'Initial Hub (Step 1)' : (parConfigureFoundry ? 'Final Hub with Foundry (Step 3)' : 'Hub Update (Step 3)')
  resourceGroup: parResourceGroupName
  customDomain: parCustomDomain
  
  // Key resource info
  resources: {
    appGatewayPublicIp: modPublicIps[0].outputs.ipAddress
    apimGatewayUrl: modApim.outputs.gatewayUrl
    apimName: parApimName
    hubVnetName: parVirtualNetworkName
  }
  
  // Auto-derived spoke names (for reference)
  derivedSpokeNames: {
    spokeVirtualNetworkName: varSpokeVirtualNetworkName
    spokeKeyVaultName: varSpokeKeyVaultName
    foundryName: varFoundryName
  }
  
  // Next steps based on deployment stage
  nextSteps: varIsFirstDeployment ? [
    '1. Deploy app.bicep (Step 2) to create spoke infrastructure'
    '2. Note the outputs: outContainerAppFqdn, outContainerAppEnvStaticIp, outOpenWebUIAppId'
    '3. Grant admin consent in Entra ID for app-open-webui'
    '4. Update main.bicepparam with spoke outputs and set parConfigureFoundry=true'
    '5. Redeploy main.bicep (Step 3)'
  ] : parConfigureFoundry ? [
    'Deployment complete! Final steps:'
    '1. Configure DNS A record: ${parCustomDomain} → ${modPublicIps[0].outputs.ipAddress}'
    '2. Import OpenAPI spec: az apim api import --resource-group ${parResourceGroupName} --service-name ${parApimName} --api-id openai --path "openai/v1" --specification-format OpenApiJson --specification-path infra/bicep/openapi/openai.openapi.json'
    '3. If using Cloudflare: Enable proxy and set SSL/TLS to Full (strict)'
  ] : [
    'Hub updated. If spoke is deployed, set parConfigureFoundry=true and redeploy.'
  ]
}
