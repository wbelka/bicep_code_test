# NAT Gateway Module

## Description
This module creates an Azure NAT Gateway and an associated Public IP address.

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `natGatewayName` | string | Yes | The name of the NAT Gateway. |
| `location` | string | Yes | The Azure region for the resources. |
| `publicIpName` | string | Yes | The name of the Public IP address to create. |
| `skuName` | string | No | The SKU for the resources. Must be 'Standard'. Default: `'Standard'`. |
| `tags` | object | No | Tags to apply to the resources. Default: `{}`. |

## Outputs
| Output | Type | Description |
|---|---|---|
| `id` | string | The resource ID of the created NAT Gateway. |
| `publicIpId` | string | The resource ID of the created Public IP address. |
