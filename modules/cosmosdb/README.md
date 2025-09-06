# Cosmos DB Module

## Description
This module creates an Azure Cosmos DB account (SQL API) and integrates it into a virtual network using a private endpoint. It handles the creation of the Cosmos DB account, the private endpoint, and the necessary private DNS configuration for name resolution.

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `cosmosAccountName` | string | Yes | The globally unique name of the Cosmos DB account. |
| `location` | string | Yes | The Azure region for the Cosmos DB account. |
| `vnetId` | string | Yes | The resource ID of the VNet for private endpoint integration. |
| `subnetId` | string | Yes | The resource ID of the subnet where the private endpoint will be placed. |
| `tags` | object | No | Tags to apply to the resources. Default: `{}`. |

## Outputs
| Output | Type | Description |
|---|---|---|
| `id` | string | The resource ID of the created Cosmos DB account. |
| `name` | string | The name of the created Cosmos DB account. |
| `endpoint` | string | The document endpoint of the created Cosmos DB account. |

## Usage Example
```bicep
// Assumes a VNet 'myVnet' and a subnet 'dbSubnet' already exist.
// These IDs would typically come from the output of a network deployment.
param dbSubnetId string
param vnetId string

module cosmos 'modules/cosmosdb/main.bicep' = {
  name: 'cosmosDeployment'
  params: {
    cosmosAccountName: 'my-unique-cosmos-12345'
    location: resourceGroup().location
    vnetId: vnetId
    subnetId: dbSubnetId
  }
}
```
