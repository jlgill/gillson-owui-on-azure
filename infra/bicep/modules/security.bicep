// Security Module - Key Vaults and Identities
targetScope = 'resourceGroup'

// Parameters
param parLocation string
param parAppGatewayName string
param parTrustedRootCertificateSecretName string
param parTrustedRootCertificateBase64 string
param parCustomDomain string

// Variables
// Generate a unique suffix for globally-namespaced resources like Key Vault
// This ensures the Key Vault name is unique across all Azure tenants
var varUniqueSuffix = uniqueString(subscription().subscriptionId, resourceGroup().name)

// Key Vault names must be globally unique (3-24 chars, alphanumeric and hyphens)
// Using take() to enforce max length: 'kv-' (3) + app gateway name (up to 21) = max 24 with room for unique suffix
var varHubKeyVaultName = take('kv-${parAppGatewayName}-${varUniqueSuffix}', 24)

var varRoleDefinitions = {
  keyVaultSecretsUser: '4633458b-17de-408a-b874-0445c86b69e6'
}

// Managed Identity for Application Gateway
module modAppGatewayIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.1' = if (!empty(parCustomDomain)) {
  params: {
    name: '${parAppGatewayName}-identity'
    location: parLocation
  }
}

// Key Vault for Hub certificates
module modHubKeyVault 'br/public:avm/res/key-vault/vault:0.13.3' = if (!empty(parCustomDomain)) {
  params: {
    name: varHubKeyVaultName
    location: parLocation
    sku: 'standard'
    enableRbacAuthorization: true
    enablePurgeProtection: false
    softDeleteRetentionInDays: 7
    secrets: [
      {
        name: parTrustedRootCertificateSecretName
        value: parTrustedRootCertificateBase64
      }
    ]
  }
}

// RBAC for App Gateway to access Hub Key Vault
// Note: Using dependsOn ensures the Key Vault exists before role assignment
// principalType: 'ServicePrincipal' avoids replication delay errors for managed identities
module modAppGatewayKeyVaultRbac 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (!empty(parCustomDomain)) {
  name: 'modAppGatewayKeyVaultRbac-${uniqueString(deployment().name)}'
  dependsOn: [
    modHubKeyVault
    modAppGatewayIdentity
  ]
  params: {
    principalId: modAppGatewayIdentity!.outputs.principalId
    principalType: 'ServicePrincipal'
    resourceId: modHubKeyVault!.outputs.resourceId
    roleDefinitionId: varRoleDefinitions.keyVaultSecretsUser
  }
}

// Outputs
output userAssignedIdentityResourceId string = !empty(parCustomDomain) ? modAppGatewayIdentity!.outputs.resourceId : ''
output userAssignedIdentityPrincipalId string = !empty(parCustomDomain) ? modAppGatewayIdentity!.outputs.principalId : ''
output hubKeyVaultResourceId string = !empty(parCustomDomain) ? modHubKeyVault!.outputs.resourceId : ''
output hubKeyVaultUri string = !empty(parCustomDomain) ? modHubKeyVault!.outputs.uri : ''
output hubKeyVaultName string = !empty(parCustomDomain) ? modHubKeyVault!.outputs.name : ''
