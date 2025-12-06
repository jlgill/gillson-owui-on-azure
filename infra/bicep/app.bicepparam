using './app.bicep'

param parResourceGroupName = 'rg-open-webui-app'
param parVirtualNetworkAddressPrefix = '10.0.4.0/22'
param parAcaSubnetAddressPrefix = '10.0.4.0/23'
param parHubResourceGroupName = 'rg-lb-core'
param parHubVirtualNetworkName = 'vnet-lb-core'
param parCustomDomain = 'openwebui.rios.engineer'
param parCertificateName = 'cloudflare-origin-cert'
