# PostgreSQL Flexible Server Module

## Description
This module creates an Azure Database for PostgreSQL (Flexible Server) inside a delegated subnet. It also creates the required Private DNS Zone and links it to the VNet for seamless name resolution.

## Prerequisites
The subnet provided via the `delegatedSubnetId` parameter **must** be delegated to `Microsoft.DBforPostgreSQL/flexibleServers` before deploying this module.

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `serverName` | string | Yes | The name of the PostgreSQL Flexible Server. |
| `location` | string | Yes | The Azure region for the server. |
| `administratorLogin` | string | Yes | The administrator login username. |
| `administratorLoginPassword` | securestring | Yes | The administrator login password. |
| `vnetId` | string | Yes | The resource ID of the VNet to link the private DNS zone to. |
| `delegatedSubnetId` | string | Yes | The resource ID of the delegated subnet to deploy the server into. |
| `sku` | object | No | The SKU for the PostgreSQL server. Default: `{ name: 'Standard_B1ms', tier: 'Burstable' }`. |
| `postgresVersion` | string | No | The version of PostgreSQL. Default: `'14'`. |
| `storageSizeGB` | int | No | The storage size in GB. Default: `32`. |
| `tags` | object | No | Tags to apply to the resources. Default: `{}`. |

## Outputs
| Output | Type | Description |
|---|---|---|
| `id` | string | The resource ID of the created PostgreSQL server. |
| `name` | string | The name of the created PostgreSQL server. |
| `fqdn` | string | The fully qualified domain name of the created PostgreSQL server. |

## Usage Example
```bicep
// Assumes a VNet 'myVnet' and a delegated subnet 'dbSubnet' already exist.
// The subnet ID would typically come from the output of a network deployment.
param dbSubnetId string
param vnetId string

module postgres 'modules/postgres/main.bicep' = {
  name: 'postgresDeployment'
  params: {
    serverName: 'my-postgres-server'
    location: resourceGroup().location
    vnetId: vnetId
    delegatedSubnetId: dbSubnetId
    administratorLogin: 'psqladmin'
    administratorLoginPassword: 'a-very-secure-password'
  }
}
```
