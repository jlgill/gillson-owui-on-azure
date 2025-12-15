targetScope = 'subscription'
// ms graph extensibility
extension 'br:mcr.microsoft.com/bicep/extensions/microsoftgraph/v1.0:1.0.0'

// ========== Type Imports ==========
import { TagsType } from './shared/types.bicep'

// ========== Parameters ==========
param parLocation string
param parResourceGroupName string
param parAppGatewayName string
param parApimName string
param parApimPublisherEmail string
param parApimPublisherName string
param parVirtualNetworkName string
param parVirtualNetworkAddressPrefix string
param parApimSubnetAddressPrefix string
param parAppGatewaySubnetAddressPrefix string
param parApimSku string
param parAppGatewaySku string
param parSpokeResourceGroupName string
param parSpokeVirtualNetworkName string
@validate(
  x => !contains(x, 'https://'), 'The Container App param FQDN must not contain the "https://" prefix.'
)
param parContainerAppFqdn string
param parContainerAppStaticIp string
param parCustomDomain string
param parSpokeKeyVaultName string
param parTrustedRootCertificateSecretName string
param parSslCertificateSecretName string
param parFoundryEndpoint string
param parTags TagsType

// ========== Existing Resources ==========
// Reference existing Entra ID app registration created by app.bicep
resource resEntraIdAppExisting 'Microsoft.Graph/applications@v1.0' existing = {
  uniqueName: 'app-open-webui'
}

// ========== Variables ==========
var varOpenWebUi = 'open-webui'
var varNsgRules = loadJsonContent('./shared/nsg-rules.json')
var varContainerAppEnvDefaultDomain = !empty(parContainerAppFqdn) ? join(skip(split(parContainerAppFqdn, '.'), 1), '.') : ''
var varContainerAppName = !empty(parContainerAppFqdn) ? split(parContainerAppFqdn, '.')[0] : ''
var varTrustedRootCertificateBase64 = loadTextContent('./cert/cloudflare-origin-ca.cer')

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

// ========== Resource Group =========
module modResourceGroup 'br/public:avm/res/resources/resource-group:0.4.2' = {
  params: {
    name: parResourceGroupName
    location: parLocation
    tags: parTags
  }
}

// ========== Networking ==========
module modNetworking 'modules/networking.bicep' = {
  scope: resourceGroup(parResourceGroupName)
  params: {
    parNamePrefix: varOpenWebUi
    parLocation: parLocation
    parVirtualNetworkName: parVirtualNetworkName
    parVirtualNetworkAddressPrefix: parVirtualNetworkAddressPrefix
    parApimSubnetAddressPrefix: parApimSubnetAddressPrefix
    parAppGatewaySubnetAddressPrefix: parAppGatewaySubnetAddressPrefix
    parSpokeResourceGroupName: parSpokeResourceGroupName
    parSpokeVirtualNetworkName: parSpokeVirtualNetworkName
    parContainerAppEnvDefaultDomain: varContainerAppEnvDefaultDomain
    parContainerAppName: varContainerAppName
    parContainerAppStaticIp: parContainerAppStaticIp
    parNsgRules: varNsgRules
  }
  dependsOn: [modResourceGroup]
}

// ========== Monitoring ==========
module modMonitoring 'modules/monitoring.bicep' = {
  scope: resourceGroup(parResourceGroupName)
  params: {
    parLocation: parLocation
    parNamePrefix: varOpenWebUi
  }
  dependsOn: [modResourceGroup]
}

// ========== Security (Identities & Key Vaults) ==========
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

// ========== RBAC for Spoke Key Vault ==========
module modAppGatewaySpokeKeyVaultRbac 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (!empty(parCustomDomain) && !empty(parSpokeKeyVaultName)) {
  scope: resourceGroup(parSpokeResourceGroupName)
  params: {
    principalId: modSecurity.outputs.userAssignedIdentityPrincipalId
    resourceId: resourceId(subscription().subscriptionId, parSpokeResourceGroupName, 'Microsoft.KeyVault/vaults', parSpokeKeyVaultName)
    roleDefinitionId: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
  }
}

// ========== Public IP Addresses ==========
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

// ========== Application Gateway ==========
module modAppGateway 'modules/app-gateway.bicep' = {
  scope: resourceGroup(parResourceGroupName)
  params: {
    parAppGatewayName: parAppGatewayName
    parLocation: parLocation
    parSku: parAppGatewaySku
    parContainerAppFqdn: parContainerAppFqdn
    parCustomDomain: parCustomDomain
    parSpokeKeyVaultName: parSpokeKeyVaultName
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

// ========== API Management ==========
module modApim 'modules/apim.bicep' = {
  scope: resourceGroup(parResourceGroupName)
  params: {
    parApimName: parApimName
    parLocation: parLocation
    parSku: parApimSku
    parPublisherEmail: parApimPublisherEmail
    parPublisherName: parApimPublisherName
    parFoundryEndpoint: parFoundryEndpoint
    parOpenWebUIAppId: resEntraIdAppExisting.appId
    parAppInsightsName: modMonitoring.outputs.appInsightsName
    parAppInsightsResourceId: modMonitoring.outputs.appInsightsResourceId
    parAppInsightsInstrumentationKey: modMonitoring.outputs.appInsightsInstrumentationKey
    parLogAnalyticsWorkspaceResourceId: modMonitoring.outputs.logAnalyticsWorkspaceResourceId
    parApimSubnetResourceId: modNetworking.outputs.apimSubnetResourceId
    parApimPublicIpResourceId: modPublicIps[1].outputs.resourceId
  }
  dependsOn: [
    modResourceGroup
  ]
}

// ========== APIM Private DNS A Record (after APIM deployment) ==========
// Get existing APIM resource to read its private IP
resource resApimExisting 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  scope: resourceGroup(parResourceGroupName)
  name: parApimName
}

module modApimDnsRecord 'br/public:avm/res/network/private-dns-zone:0.8.0' = {
  scope: resourceGroup(parResourceGroupName)
  name: 'apimDnsRecord'
  params: {
    name: modNetworking.outputs.apimPrivateDnsZoneName
    location: 'global'
    a: [
      {
        name: parApimName
        ttl: 3600
        aRecords: [
          { ipv4Address: resApimExisting.properties.privateIPAddresses[0] }
        ]
      }
    ]
  }
}

// ========== Outputs ==========
output outApimName string = modApim.outputs.name
output outApimResourceId string = modApim.outputs.resourceId
output outApimGatewayUrl string = modApim.outputs.gatewayUrl
output outApimSystemAssignedPrincipalId string = modApim.outputs.systemAssignedMIPrincipalId
output outAppInsightsConnectionString string = modMonitoring.outputs.appInsightsConnectionString
output outAppInsightsResourceId string = modMonitoring.outputs.appInsightsResourceId
output outAppGatewayPublicIp string = modPublicIps[0].outputs.resourceId
output outApimPublicIp string = modPublicIps[1].outputs.ipAddress
output outVirtualNetworkResourceId string = modNetworking.outputs.virtualNetworkResourceId
output outVirtualNetworkName string = modNetworking.outputs.virtualNetworkName
output outContainerAppFqdn string = parContainerAppFqdn
