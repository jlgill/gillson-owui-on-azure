// Networking Module
targetScope = 'resourceGroup'

// Parameters
param parNamePrefix string
param parLocation string
param parVirtualNetworkName string
param parVirtualNetworkAddressPrefix string
param parApimSubnetAddressPrefix string
param parAppGatewaySubnetAddressPrefix string
param parRedisCacheSubnetAddressPrefix string
param parSpokeResourceGroupName string
param parSpokeVirtualNetworkName string
param parContainerAppEnvDefaultDomain string
param parContainerAppName string
param parContainerAppStaticIp string
param parNsgRules array

// NSG for APIM Subnet
module modNsgApim 'br/public:avm/res/network/network-security-group:0.5.2' = {
  params: {
    name: '${parNamePrefix}-apim-nsg'
    location: parLocation
    securityRules: parNsgRules
  }
}

// Route Table for APIM Subnet (prevents forced tunneling)
module modApimRouteTable 'br/public:avm/res/network/route-table:0.5.0' = {
  params: {
    name: '${parNamePrefix}-apim-rt'
    location: parLocation
    routes: [
      {
        name: 'apim-management-endpoint'
        properties: {
          addressPrefix: 'ApiManagement'
          nextHopType: 'Internet'
        }
      }
    ]
  }
}

// Virtual Network
module modVirtualNetwork 'br/public:avm/res/network/virtual-network:0.7.1' = {
  params: {
    name: parVirtualNetworkName
    location: parLocation
    addressPrefixes: [
      parVirtualNetworkAddressPrefix
    ]
    subnets: [
      {
        name: 'apim-subnet'
        addressPrefix: parApimSubnetAddressPrefix
        networkSecurityGroupResourceId: modNsgApim.outputs.resourceId
        routeTableResourceId: modApimRouteTable.outputs.resourceId
        serviceEndpoints: [
          'Microsoft.Storage'
          'Microsoft.Sql'
          'Microsoft.EventHub'
          'Microsoft.KeyVault'
          'Microsoft.ServiceBus'
          'Microsoft.AzureActiveDirectory'
        ]
      }
      {
        name: 'appgw-subnet'
        addressPrefix: parAppGatewaySubnetAddressPrefix
      }
      {
        name: 'redis-subnet'
        addressPrefix: parRedisCacheSubnetAddressPrefix
        privateEndpointNetworkPolicies: 'Disabled'
      }
    ]
    peerings: !empty(parSpokeVirtualNetworkName) ? [
      {
        remoteVirtualNetworkResourceId: resourceId(subscription().subscriptionId, parSpokeResourceGroupName, 'Microsoft.Network/virtualNetworks', parSpokeVirtualNetworkName)
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        useRemoteGateways: false
      }
    ] : []
  }
}

// Private DNS Zone for Container App
module modPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.0' = if (!empty(parContainerAppEnvDefaultDomain)) {
  name: 'privateDnsZone'
  params: {
    name: parContainerAppEnvDefaultDomain
    location: 'global'
    a: [
      {
        name: parContainerAppName
        ttl: 3600
        aRecords: [
          { ipv4Address: parContainerAppStaticIp }
        ]
      }
    ]
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: modVirtualNetwork.outputs.resourceId
        registrationEnabled: false
      }
    ]
  }
}

// Private DNS Zone for APIM (Internal mode) - A record will be created after APIM deployment
module modApimPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.0' = {
  name: 'apimPrivateDnsZone'
  params: {
    name: 'azure-api.net'
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: modVirtualNetwork.outputs.resourceId
        registrationEnabled: false
      }
      {
        virtualNetworkResourceId: resourceId(subscription().subscriptionId, parSpokeResourceGroupName, 'Microsoft.Network/virtualNetworks', parSpokeVirtualNetworkName)
        registrationEnabled: false
      }
    ]
  }
}

// Outputs
output virtualNetworkResourceId string = modVirtualNetwork.outputs.resourceId
output virtualNetworkName string = modVirtualNetwork.outputs.name
output subnetResourceIds array = modVirtualNetwork.outputs.subnetResourceIds
output apimSubnetResourceId string = modVirtualNetwork.outputs.subnetResourceIds[0]
output appGatewaySubnetResourceId string = modVirtualNetwork.outputs.subnetResourceIds[1]
output redisCacheSubnetResourceId string = modVirtualNetwork.outputs.subnetResourceIds[2]
output apimPrivateDnsZoneName string = modApimPrivateDnsZone.outputs.name
