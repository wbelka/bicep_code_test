# Resource Group Module

## Description
This module creates an Azure Resource Group at the subscription level. It's designed to be the foundational module for deploying other Azure resources.

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `resourceGroupName` | string | Yes | The name of the resource group to create. |
| `location` | string | Yes | The Azure region where the resource group should be created (e.g., 'eastus', 'westeurope'). |
| `tags` | object | No | Tags to apply to the resource group. Default: `{}`. |

## Outputs
| Output | Type | Description |
|---|---|---|
| `resourceGroupId` | string | The full resource ID of the created resource group. |
| `resourceGroupName` | string | The name of the created resource group. |
| `resourceGroupLocation` | string | The location of the created resource group. |

## Usage Example
In a main deployment file:
```bicep
targetScope = 'subscription'

module rg 'modules/resourcegroup/main.bicep' = {
  name: 'resourceGroupDeployment'
  params: {
    resourceGroupName: 'myResourceGroup'
    location: 'eastus'
    tags: {
      Environment: 'Development'
      Project: 'MyProject'
    }
  }
}
```

## Notes
- This module must be deployed at subscription scope (`targetScope = 'subscription'`).
- The resource group name must be unique within the subscription.
- Location should be a valid Azure region.
