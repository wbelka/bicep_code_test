# Azure Kubernetes Service (AKS) Module

## Description
This module creates an Azure Kubernetes Service (AKS) cluster with a focus on secure, modern practices. It uses the "Greenfield" deployment model for the Application Gateway Ingress Controller (AGIC), where the add-on provisions and manages a new Application Gateway resource.

## Key Features
- Creates an AKS cluster with a System-Assigned Managed Identity.
- **Greenfield AGIC**: Deploys a new Application Gateway managed by the AGIC add-on.
- **Key Vault Integration**: Enables the Azure Key Vault Provider for Secrets Store CSI Driver (`azureKeyvaultSecretsProvider`) and grants the AKS identity access to a specified Key Vault.
- **CSI Drivers**: Enables `azureDiskCSIDriver` and `azureFileCSIDriver` for persistent storage.
- Configurable node pools and Kubernetes version.

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `clusterName` | string | Yes | The name of the AKS cluster. |
| `location` | string | Yes | The Azure region for the cluster. |
| `dnsPrefix` | string | Yes | The DNS prefix for the FQDN of the cluster's API server. |
| `clusterSubnetId` | string | Yes | The resource ID of the subnet for the AKS nodes. |
| `appGatewaySubnetId` | string | Yes | The resource ID of the subnet where the new Application Gateway will be created by AGIC. |
| `keyVaultId` | string | Yes | The resource ID of the Key Vault to integrate with for the Secrets Store CSI driver. |
| `kubernetesVersion` | string | No | The version of Kubernetes. Default: `1.28.5`. |
| `agentPoolProfiles` | array | No | An array of objects defining the node pools. Defaults to a single system node. |
| `appGatewayConfig` | object | No | An object with configuration for the Application Gateway to be created. Default: `{ sku: 'WAF_v2' }`. |
| `tags` | object | No | Tags to apply to the resources. Default: `{}`. |

### `agentPoolProfiles` Object Structure
```json
[
  {
    "name": "systempool",
    "count": 1,
    "vmSize": "Standard_DS2_v2",
    "osType": "Linux",
    "mode": "System",
    "vnetSubnetID": "<your-cluster-subnet-id>"
  }
]
```

### `appGatewayConfig` Object Structure
```json
{
  "sku": "WAF_v2"
}
```

## Outputs
| Output | Type | Description |
|---|---|---|
| `id` | string | The resource ID of the created AKS cluster. |
| `name` | string | The name of the created AKS cluster. |
| `principalId`| string | The principal ID of the cluster's system-assigned managed identity. |

## Usage Example
```bicep
// Assumes network and keyvault deployments have provided these outputs
param clusterSubnetId string
param appGatewaySubnetId string
param keyVaultId string

module aks 'modules/aks/main.bicep' = {
  name: 'aksDeployment'
  params: {
    clusterName: 'my-aks-cluster'
    location: resourceGroup().location
    dnsPrefix: 'myakscluster'
    clusterSubnetId: clusterSubnetId
    appGatewaySubnetId: appGatewaySubnetId
    keyVaultId: keyVaultId
  }
}
```
