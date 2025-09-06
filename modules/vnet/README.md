# Virtual Network (VNet) Module

## Description
This module creates an Azure Virtual Network, a variable number of subnets, and optionally creates and associates a Network Security Group (NSG) for each subnet.

## Dependencies
This module uses the `nsg` module located at `../nsg/`.

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `vnetName` | string | Yes | The name of the Virtual Network to create. |
| `location` | string | Yes | The Azure region where all resources should be created. |
| `addressPrefixes` | array | Yes | An array of address prefixes for the VNet (e.g., `['10.1.0.0/16']`). |
| `subnets` | array | Yes | An array of subnet objects to create. See below for the object structure. |
| `tags` | object | No | Tags to apply to all created resources. Default: `{}`. |

### Subnet Object Structure
Each object in the `subnets` array defines a subnet and can have the following properties:

| Property | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | The name of the subnet. |
| `addressPrefix` | string | Yes | The address prefix for the subnet (e.g., `10.1.1.0/24`). |
| `nsgRules` | array | No | If provided, a new NSG will be created with these rules and associated with the subnet. The structure of each rule object is the same as in the `nsg` module. |
| `privateEndpointNetworkPoliciesEnabled`| boolean | No | If `true`, enables network policies for private endpoints on this subnet. Default: `false`. |
| `delegations` | array | No | An array of delegation objects for the subnet. This is required for services like Azure PostgreSQL Flexible Server. |

**Example `subnets` array:**
```json
[
  {
    "name": "web-subnet",
    "addressPrefix": "10.1.1.0/24",
    "nsgRules": [
      {
        "name": "AllowWebInbound",
        "protocol": "Tcp",
        "destinationPortRange": [ "80", "443" ],
        "sourceAddressPrefix": "Internet",
        "access": "Allow",
        "priority": 100,
        "direction": "Inbound"
      }
    ]
  },
  {
    "name": "db-subnet",
    "addressPrefix": "10.1.2.0/24",
    "privateEndpointNetworkPoliciesEnabled": false,
    "delegations": [
      {
        "name": "postgresql-delegation",
        "properties": {
          "serviceName": "Microsoft.DBforPostgreSQL/flexibleServers"
        }
      }
    ]
  }
]
```

## Outputs
| Output | Type | Description |
|---|---|---|
| `id` | string | The full resource ID of the created Virtual Network. |
| `name` | string | The name of the created Virtual Network. |
| `subnets` | array | An array of objects representing the created subnets, including their `name`, `id`, and `addressPrefix`. |
| `subnetIdsByName` | object | A lookup object (dictionary) mapping subnet names to their resource IDs. |
