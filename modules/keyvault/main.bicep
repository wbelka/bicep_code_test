@description('Required. The name of the Key Vault. Must be globally unique.')
param keyVaultName string

@description('Required. The location for the Key Vault.')
param location string

@description('Required. The object ID of the principal to be granted Key Vault Administrator role.')
param adminObjectId string

@description('Required. The type of the principal. Allowed values: User, Group, ServicePrincipal.')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
])
param adminPrincipalType string = 'ServicePrincipal'

@description('Optional. The name of a secret to create inside the Key Vault.')
param secretName string = ''

@description('Optional. The value for the secret. Required if secretName is provided.')
@secure()
param secretValue string = ''

@description('Optional. Tags to apply to the Key Vault.')
param tags object = {}

// Static GUID for the 'Key Vault Administrator' role
var keyVaultAdministratorRoleId = '00482a5a-887f-4fb3-b363-3b7fe8e74483'
var tenantId = subscription().tenantId

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    enableRbacAuthorization: true
  }
}

resource adminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: kv
  name: guid(kv.id, adminObjectId, keyVaultAdministratorRoleId)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultAdministratorRoleId)
    principalId: adminObjectId
    principalType: adminPrincipalType
  }
}

// Conditionally create the secret
resource secretResource 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!empty(secretName)) {
  parent: kv
  name: secretName
  properties: {
    value: secretValue
  }
}

@description('The resource ID of the created Key Vault.')
output id string = kv.id

@description('The name of the created Key Vault.')
output name string = kv.name

@description('The URI of the created Key Vault.')
output uri string = kv.properties.vaultUri
