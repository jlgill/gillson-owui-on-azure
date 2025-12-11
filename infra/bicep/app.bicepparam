using './app.bicep'

param parResourceGroupName = 'rg-open-webui-app'
param parVirtualNetworkAddressPrefix = '10.0.4.0/22'
param parAcaSubnetAddressPrefix = '10.0.4.0/23'
param parHubResourceGroupName = 'rg-lb-core'
param parHubVirtualNetworkName = 'vnet-lb-core'
param parCustomDomain = 'openwebui.rios.engineer'
param parCertificateName = 'cloudflare-origin-cert'
param parApimPrincipalId = 'd5d3423b-9834-4714-be94-c7530d92fd40'
param parApimGatewayUrl = 'https://apim-open-webui.azure-api.net'
param parApimAllowedIpAddresses = [
	'145.133.116.11' // APIM VIP - New Foundry doesn't support end to end private networking yet.
]

param parContainerAppAllowedIpAddresses = [
	'188.74.98.58/32' // My IP for testing
	'10.0.0.64/26' // App Gateway subnet
]

param parFoundryDeployments = [
	{
		name: 'gpt-4o'
		model: {
			format: 'OpenAI'
			name: 'gpt-4o'
			version: '2024-11-20'
		}
		sku: {
			name: 'GlobalStandard'
			capacity: 100
		}
	}
	{
		name: 'gpt-4o-mini'
		model: {
			format: 'OpenAI'
			name: 'gpt-4o-mini'
			version: '2024-07-18'
		}
		sku: {
			name: 'GlobalStandard'
			capacity: 100
		}
	}
	{
		name: 'gpt-5-mini'
		model: {
			format: 'OpenAI'
			name: 'gpt-5-mini'
			version: '2025-08-07'
		}
		sku: {
			name: 'GlobalStandard'
			capacity: 100
		}
	}
	{
		name: 'Mistral-Large-3'
		model: {
			format: 'Mistral AI'
			name: 'Mistral-Large-3'
			version: '1'
		}
		sku: {
			name: 'GlobalStandard'
			capacity: 100
		}
	}
	{
		name: 'mistral-document-ai-2505'
		model: {
			format: 'Mistral AI'
			name: 'mistral-document-ai-2505'
			version: '1'
		}
		sku: {
			name: 'GlobalStandard'
			capacity: 100
		}
	}
	{
		name: 'FLUX-1.1-pro'
		model: {
			format: 'Black Forest Labs'
			name: 'FLUX-1.1-pro'
			version: '1'
		}
		sku: {
			name: 'GlobalStandard'
			capacity: 50
		}
	}
]
