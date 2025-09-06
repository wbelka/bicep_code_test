@description('Required. The name of the AKS cluster.')
param clusterName string

@description('Required. The location for the AKS cluster.')
param location string

@description('Required. The DNS prefix for the AKS cluster.')
param dnsPrefix string

@description('Required. The resource ID of the subnet for the AKS nodes. This is derived from the vnet module output.')
param clusterSubnetId string

@description('Required. The resource ID of the subnet for the Application Gateway created by AGIC. This is derived from the vnet module output.')
param appGatewaySubnetId string

@description('Required. The resource ID of the Key Vault for CSI driver integration.')
param keyVaultId string

@description('Optional. The version of Kubernetes to deploy.')
param kubernetesVersion string = '1.28.5'

@description('Optional. Configuration for the node pools.')
param agentPoolProfiles array = [
  {
    name: 'systempool'
    count: 1
    vmSize: 'Standard_DS2_v2'
    osType: 'Linux'
    mode: 'System'
    vnetSubnetID: clusterSubnetId // Associate node pool with the cluster subnet
  }
]

@description('Optional. Configuration for the Application Gateway created by AGIC.')
param appGatewayConfig object = {
  sku: 'WAF_v2'
}

@description('Optional. Tags to apply to the resources.')
param tags object = {}

// Role Definition IDs
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

// Get a reference to the existing Key Vault to use for role assignment scope
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: last(split(keyVaultId, '/'))
}

resource aks 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: clusterName
  location: location
  tags: tags
  dnsPrefix: dnsPrefix
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    agentPoolProfiles: agentPoolProfiles
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
    }
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
        }
      }
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayName: '${clusterName}-agic-gw'
          subnetID: appGatewaySubnetId
          gatewaySKU: appGatewayConfig.sku
        }
      }
      azureDiskCSIDriver: {
        enabled: true
      }
      azureFileCSIDriver: {
        enabled: true
      }
    }
  }
}

// Grant the AKS Managed Identity access to the Key Vault
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(aks.id, keyVault.id, keyVaultSecretsUserRoleId)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: aks.identity.principalId
    principalType: 'ServicePrincipal' // System-assigned identities are represented as Service Principals
  }
}

@description('The resource ID of the created AKS cluster.')
output id string = aks.id

@description('The name of the created AKS cluster.')
output name string = aks.name

@description('The principal ID of the AKS managed identity.')
output principalId string = aks.identity.principalId
