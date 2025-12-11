targetScope = 'subscription'
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
param parSpokeResourceGroupName string
param parSpokeVirtualNetworkName string
@validate(
  x => !contains(x, 'https://'), 'The Container App param FQDN must not contain the "https://" prefix.'
)
param parContainerAppFqdn string
param parContainerAppStaticIp string
param parCustomDomain string
param parSpokeKeyVaultName string
param parOpenWebUIAppId string
param parTrustedRootCertificateSecretName string = 'cloudflare-origin-ca'
param parSslCertificateSecretName string = 'cloudflare-origin-cert'
param parFoundryEndpoint string
// ========== Variables ==========
var varOpenWebUi = 'open-webui'
var varNsgRules = loadJsonContent('nsg-rules.json')
var varContainerAppEnvDefaultDomain = !empty(parContainerAppFqdn) ? join(skip(split(parContainerAppFqdn, '.'), 1), '.') : ''
var varContainerAppName = !empty(parContainerAppFqdn) ? split(parContainerAppFqdn, '.')[0] : ''
var varTrustedRootCertificateBase64 = loadTextContent('cloudflare-origin-ca.cer')

// ========== Resource Group =========
module modResourceGroup 'br/public:avm/res/resources/resource-group:0.4.2' = {
  params: {
    name: parResourceGroupName
    location: parLocation
  }
}

// ========== Networking ==========
module modNetworking 'modules/networking.bicep' = {
  scope: resourceGroup(parResourceGroupName)
  params: {
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

// ========== Application Gateway Public IP ==========
module modAppGatewayPublicIp 'br/public:avm/res/network/public-ip-address:0.8.0' = {
  scope: resourceGroup(parResourceGroupName)
  params: {
    name: '${parAppGatewayName}-pip'
    location: parLocation
    skuName: 'Standard'
    publicIPAllocationMethod: 'Static'
    zones: []
  }
  dependsOn: [modResourceGroup]
}

// ========== APIM Public IP ==========
module modApimPublicIp 'br/public:avm/res/network/public-ip-address:0.8.0' = {
  scope: resourceGroup(parResourceGroupName)
  params: {
    name: 'apim-${parApimName}-pip'
    location: parLocation
    zones: []
    skuName: 'Standard'
    publicIPAllocationMethod: 'Static'
  }
  dependsOn: [
    modResourceGroup
  ]
}

// ========== Application Gateway ==========
module modAppGateway 'modules/app-gateway.bicep' = {
  scope: resourceGroup(parResourceGroupName)
  params: {
    parAppGatewayName: parAppGatewayName
    parLocation: parLocation
    parApimName: parApimName
    parContainerAppFqdn: parContainerAppFqdn
    parCustomDomain: parCustomDomain
    parSpokeKeyVaultName: parSpokeKeyVaultName
    parTrustedRootCertificateSecretName: parTrustedRootCertificateSecretName
    parSslCertificateSecretName: parSslCertificateSecretName
    parAppGatewaySubnetId: modNetworking.outputs.appGatewaySubnetResourceId
    parPublicIpResourceId: modAppGatewayPublicIp.outputs.resourceId
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
    parPublisherEmail: parApimPublisherEmail
    parPublisherName: parApimPublisherName
    parFoundryEndpoint: parFoundryEndpoint
    parOpenWebUIAppId: parOpenWebUIAppId
    parAppInsightsName: modMonitoring.outputs.appInsightsName
    parAppInsightsResourceId: modMonitoring.outputs.appInsightsResourceId
    parAppInsightsInstrumentationKey: modMonitoring.outputs.appInsightsInstrumentationKey
    parLogAnalyticsWorkspaceResourceId: modMonitoring.outputs.logAnalyticsWorkspaceResourceId
    parApimSubnetResourceId: modNetworking.outputs.apimSubnetResourceId
    parApimPublicIpResourceId: modApimPublicIp.outputs.resourceId
  }
  dependsOn: [
    modResourceGroup
  ]
}

// ========== Outputs ==========
output outApimName string = modApim.outputs.name
output outApimResourceId string = modApim.outputs.resourceId
output outApimGatewayUrl string = modApim.outputs.gatewayUrl
output outApimSystemAssignedPrincipalId string = modApim.outputs.systemAssignedMIPrincipalId
output outAppInsightsConnectionString string = modMonitoring.outputs.appInsightsConnectionString
output outAppInsightsResourceId string = modMonitoring.outputs.appInsightsResourceId
output outAppGatewayPublicIp string = modAppGatewayPublicIp.outputs.resourceId
output outApimPublicIp string = modApimPublicIp.outputs.ipAddress
output outVirtualNetworkResourceId string = modNetworking.outputs.virtualNetworkResourceId
output outVirtualNetworkName string = modNetworking.outputs.virtualNetworkName
output outContainerAppFqdn string = parContainerAppFqdn
