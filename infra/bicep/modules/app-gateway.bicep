// Application Gateway Module (wrapper around AVM module)
targetScope = 'resourceGroup'

// Parameters
param parAppGatewayName string
param parLocation string
param parSku string
param parContainerAppFqdn string
param parCustomDomain string
param parSpokeKeyVaultName string
param parTrustedRootCertificateSecretName string
param parSslCertificateSecretName string
param parAppGatewaySubnetId string
param parPublicIpResourceId string
param parUserAssignedIdentityResourceId string
param parHubKeyVaultUri string
param parResourceGroupName string

// Determine if we have SSL cert available (spoke Key Vault exists with cert)
var varHasSslCert = !empty(parCustomDomain) && !empty(parSpokeKeyVaultName)

// Application Gateway using AVM module
module modAppGateway 'br/public:avm/res/network/application-gateway:0.6.0' = {
  params: {
    name: parAppGatewayName
    location: parLocation
    sku: parSku
    capacity: 1
    zones: []
    managedIdentities: !empty(parCustomDomain) ? {
      userAssignedResourceIds: [
        parUserAssignedIdentityResourceId
      ]
    } : null
    trustedRootCertificates: varHasSslCert ? [
      {
        name: parTrustedRootCertificateSecretName
        properties: {
          keyVaultSecretId: '${parHubKeyVaultUri}secrets/${parTrustedRootCertificateSecretName}'
        }
      }
    ] : []
    sslCertificates: varHasSslCert ? [
      {
        name: parSslCertificateSecretName
        properties: {
          keyVaultSecretId: 'https://${parSpokeKeyVaultName}${environment().suffixes.keyvaultDns}/secrets/${parSslCertificateSecretName}'
        }
      }
    ] : []
    gatewayIPConfigurations: [
      {
        name: 'appgw-ip-config'
        properties: {
          subnet: {
            id: parAppGatewaySubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appgw-frontend-ip'
        properties: {
          publicIPAddress: {
            id: parPublicIpResourceId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port-80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port-443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'containerapp-backend-pool'
        properties: {
          backendAddresses: !empty(parContainerAppFqdn) ? [
            {
              fqdn: parContainerAppFqdn
            }
          ] : []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'containerapp-backend-settings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Enabled'
          pickHostNameFromBackendAddress: !empty(parCustomDomain) ? false : true
          hostName: !empty(parCustomDomain) ? parCustomDomain : null
          // Bump timeout to tolerate slower cold starts and long requests (default is 30s)
          requestTimeout: 120
          trustedRootCertificates: varHasSslCert ? [
            {
              id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/trustedRootCertificates', parAppGatewayName, parTrustedRootCertificateSecretName)
            }
          ] : null
          probe: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/probes', parAppGatewayName, 'containerapp-health-probe')
          }
        }
      }
    ]
    probes: [
      {
        name: 'containerapp-health-probe'
        properties: {
          protocol: 'Https'
          // Use a lightweight API endpoint and give more time for cold starts
          path: '/api/version'
          interval: 30
          timeout: 60
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {
            statusCodes: ['200-399']
          }
        }
      }
    ]
    // HTTP listeners - always include HTTP, conditionally include HTTPS
    httpListeners: varHasSslCert ? [
      // HTTP listener (for redirect to HTTPS)
      {
        name: 'containerapp-http-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/frontendIPConfigurations', parAppGatewayName, 'appgw-frontend-ip')
          }
          frontendPort: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/frontendPorts', parAppGatewayName, 'port-80')
          }
          protocol: 'Http'
          hostName: parCustomDomain
        }
      }
      // HTTPS listener (only when SSL cert available)
      {
        name: 'containerapp-https-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/frontendIPConfigurations', parAppGatewayName, 'appgw-frontend-ip')
          }
          frontendPort: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/frontendPorts', parAppGatewayName, 'port-443')
          }
          protocol: 'Https'
          hostName: parCustomDomain
          sslCertificate: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/sslCertificates', parAppGatewayName, parSslCertificateSecretName)
          }
        }
      }
    ] : [
      // HTTP-only listener (first deployment - no SSL cert yet)
      {
        name: 'containerapp-http-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/frontendIPConfigurations', parAppGatewayName, 'appgw-frontend-ip')
          }
          frontendPort: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/frontendPorts', parAppGatewayName, 'port-80')
          }
          protocol: 'Http'
          hostName: parCustomDomain
        }
      }
    ]
    // Routing rules - different config based on SSL availability
    requestRoutingRules: varHasSslCert ? [
      // HTTP to HTTPS redirect rule
      {
        name: 'containerapp-routing-rule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/httpListeners', parAppGatewayName, 'containerapp-http-listener')
          }
          redirectConfiguration: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/redirectConfigurations', parAppGatewayName, 'http-to-https-redirect')
          }
        }
      }
      // HTTPS routing rule
      {
        name: 'containerapp-https-routing-rule'
        properties: {
          ruleType: 'Basic'
          priority: 101
          httpListener: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/httpListeners', parAppGatewayName, 'containerapp-https-listener')
          }
          backendAddressPool: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/backendAddressPools', parAppGatewayName, 'containerapp-backend-pool')
          }
          backendHttpSettings: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/backendHttpSettingsCollection', parAppGatewayName, 'containerapp-backend-settings')
          }
        }
      }
    ] : [
      // HTTP-only rule (first deployment - routes directly to backend)
      {
        name: 'containerapp-routing-rule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/httpListeners', parAppGatewayName, 'containerapp-http-listener')
          }
          backendAddressPool: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/backendAddressPools', parAppGatewayName, 'containerapp-backend-pool')
          }
          backendHttpSettings: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/backendHttpSettingsCollection', parAppGatewayName, 'containerapp-backend-settings')
          }
        }
      }
    ]
    // Redirect config - only when SSL available
    redirectConfigurations: varHasSslCert ? [
      {
        name: 'http-to-https-redirect'
        properties: {
          redirectType: 'Permanent'
          targetListener: {
            id: resourceId(subscription().subscriptionId, parResourceGroupName, 'Microsoft.Network/applicationGateways/httpListeners', parAppGatewayName, 'containerapp-https-listener')
          }
          includePath: true
          includeQueryString: true
        }
      }
    ] : []
  }
}

// Outputs
output resourceId string = modAppGateway.outputs.resourceId
output name string = modAppGateway.outputs.name
