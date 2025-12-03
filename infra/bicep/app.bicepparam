using './app.bicep'

param parResourceGroupName = 'rg-open-webui-app'
param parVirtualNetworkAddressPrefix = '10.0.4.0/22'
param parAcaSubnetAddressPrefix = '10.0.4.0/23' //consumption aca still has hard req on /23 subnet
