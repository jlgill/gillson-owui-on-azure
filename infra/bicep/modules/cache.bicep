

// Redis Cache Module for APIM AI Gateway Semantic Caching
targetScope = 'resourceGroup'

// Parameters
param parCacheName string
param parLocation string
param parSkuName string
param parSubnetResourceId string
param parHubVnetResourceId string
param parSpokeVnetResourceId string
param parTags object = {}

module modPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.0' = {
  params: {
    name: 'privatelink.redisenterprise.cache.azure.net'
    location: 'global'
    tags: parTags
    virtualNetworkLinks: [
      {
        name: 'hub-vnet-link'
        virtualNetworkResourceId: parHubVnetResourceId
        registrationEnabled: false
      }
      {
        name: 'spoke-vnet-link'
        virtualNetworkResourceId: parSpokeVnetResourceId
        registrationEnabled: false
      }
    ]
  }
}

// Azure Managed Redis (redis-enterprise)
module modRedisCache 'br/public:avm/res/cache/redis-enterprise:0.5.0' = {
  params: {
    name: parCacheName
    location: parLocation
    tags: parTags
    skuName: parSkuName
    capacity: 2
    database: {
      name: 'default'
      clientProtocol: 'Encrypted'
      clusteringPolicy: 'NoCluster'
      evictionPolicy: 'AllKeysLRU'
      port: 10000
    }
    privateEndpoints: [
      {
        subnetResourceId: parSubnetResourceId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: modPrivateDnsZone.outputs.resourceId
            }
          ]
        }
      }
    ]
  }
}

// Outputs
output resourceId string = modRedisCache.outputs.resourceId
output name string = modRedisCache.outputs.name
output hostName string = modRedisCache.outputs.hostName
output sslPort int = modRedisCache.outputs.port
