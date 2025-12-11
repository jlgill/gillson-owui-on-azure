

module modRedisCache 'br/public:avm/res/cache/redis:0.16.4' = {
  params: {
    name: parCacheName
    location: parLocation
    sku: {
      name: 'Standard'
      family: 'C'
      capacity: 1
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    subnetResourceId: parSubnetResourceId

  }
}
