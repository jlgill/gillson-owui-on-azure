using 'main.bicep'

// ========== Shared Configuration ==========
// Import shared config to ensure consistency with app.bicep
import { sharedConfig, placeholderMarker } from './shared/config.bicep'

// ========== IMPORTANT: Review shared/config.bicep first ==========
// Most configuration values are centralized there. Only override here if needed.

// ===== Core Configuration (from shared config) =====
param parLocation = sharedConfig.location
param parCustomDomain = sharedConfig.customDomain
param parApimPublisherEmail = sharedConfig.apimPublisherEmail
param parApimPublisherName = sharedConfig.apimPublisherName
param parApimName = sharedConfig.apimName
param parAppGatewayName = sharedConfig.appGatewayName
param parResourceGroupName = sharedConfig.hubResourceGroupName
param parVirtualNetworkName = sharedConfig.hubVirtualNetworkName
param parSpokeResourceGroupName = sharedConfig.spokeResourceGroupName
param parTags = sharedConfig.tags

// ===== Network Configuration (from shared config) =====
param parVirtualNetworkAddressPrefix = sharedConfig.hubVnetAddressPrefix
param parApimSubnetAddressPrefix = sharedConfig.apimSubnetAddressPrefix
param parAppGatewaySubnetAddressPrefix = sharedConfig.appGatewaySubnetAddressPrefix
param parPeSubnetAddressPrefix = sharedConfig.peSubnetAddressPrefix

// ===== SKU Configuration (from shared config) =====
param parApimSku = sharedConfig.apimSku
param parAppGatewaySku = sharedConfig.appGatewaySku

// ===== Certificate Configuration (from shared config) =====
param parTrustedRootCertificateSecretName = sharedConfig.trustedRootCertificateSecretName
param parSslCertificateSecretName = sharedConfig.sslCertificateName

// ===== Spoke Name Prefix =====
// Used to auto-derive spoke resource names (VNet, Key Vault, Foundry)
// Must match parNamePrefix in app.bicepparam
param parSpokeNamePrefix = sharedConfig.spokeNamePrefix

// ========== Step 2 Outputs ==========
// IMPORTANT: These values must be updated AFTER running app.bicep (Step 2)
// Get these values from the app.bicep deployment outputs:
//   - parContainerAppFqdn: outContainerAppFqdn
//   - parContainerAppStaticIp: outContainerAppEnvStaticIp
//   - parOpenWebUIAppId: outOpenWebUIAppId
//
// On first deployment, leave as placeholders - the deployment will handle this gracefully.
// After Step 2, update these values and redeploy with parConfigureFoundry=true

param parContainerAppFqdn = 'owui-app-aca.nicedune-c71b030a.westus.azurecontainerapps.io'
param parContainerAppStaticIp = '10.0.4.99'
param parOpenWebUIAppId = '26313121-1f1d-4263-846f-90e5385adab3'

// ========== Foundry Configuration ==========
// Set to true on SECOND hub deployment after Foundry exists (Step 3)
// First deployment: false (creates hub networking + APIM without Foundry backend)
// Second deployment: true (configures APIM with Foundry endpoint + RBAC)
param parConfigureFoundry = false
