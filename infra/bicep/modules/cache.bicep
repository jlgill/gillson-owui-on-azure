

// Redis Cache Module for APIM AI Gateway Semantic Caching
targetScope = 'resourceGroup'

// Parameters
param parCacheName string
param parLocation string
param parSubnetResourceId string
param parHubVnetResourceId string
param parSpokeVnetResourceId string
param parTags object = {}

// Private DNS Zone for Redis Cache (must be created first for private endpoint)
module modPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.0' = {
  params: {
    name: 'privatelink.redis.cache.windows.net'
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

// Redis Cache for APIM
module modRedisCache 'br/public:avm/res/cache/redis:0.16.4' = {
  params: {
    name: parCacheName
    location: parLocation
    tags: parTags
    skuName: 'Standard'
    capacity: 1
    disableAccessKeyAuthentication: true
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'
      'maxmemory-reserved': '50'
    }
    redisVersion: '6'
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
output sslPort int = modRedisCache.outputs.sslPort
