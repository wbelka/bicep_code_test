# Network Security Group (NSG) Module

## Description
This module creates an Azure Network Security Group (NSG) with a specified set of security rules.

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `nsgName` | string | Yes | The name of the Network Security Group to create. |
| `location` | string | Yes | The Azure region where the NSG should be created. |
| `securityRules` | array | No | An array of security rule objects to apply to the NSG. See below for the rule object structure. Default: `[]`. |
| `tags` | object | No | Tags to apply to the NSG. Default: `{}`. |

### Security Rule Object Structure
Each object in the `securityRules` array must have the following structure:
```json
{
  "name": "AllowSSH",
  "description": "Allow SSH from a specific source",
  "protocol": "Tcp",
  "sourcePortRange": "*",
  "destinationPortRange": "22",
  "sourceAddressPrefix": "1.2.3.4/32",
  "destinationAddressPrefix": "*",
  "access": "Allow",
  "priority": 100,
  "direction": "Inbound"
}
```

## Outputs
| Output | Type | Description |
|---|---|---|
| `id` | string | The full resource ID of the created Network Security Group. |
| `name` | string | The name of the created Network Security Group. |

## Usage Example
```bicep
module myNsg 'modules/nsg/main.bicep' = {
  name: 'myNsgDeployment'
  params: {
    nsgName: 'my-nsg'
    location: resourceGroup().location
    securityRules: [
      {
        name: 'AllowWebInbound'
        description: 'Allow HTTP and HTTPS'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: [
          '80'
          '443'
        ]
        sourceAddressPrefix: 'Internet'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 100
        direction: 'Inbound'
      }
    ]
  }
}
```
