@description('Required. The name of the Virtual Network.')
param vnetName string

@description('Required. The location for all resources in this module.')
param location string

@description('Required. The address space for the Virtual Network (e.g., \'10.0.0.0/16\').')
param addressPrefixes array

@description('Required. An array of subnet objects to create in the Virtual Network.')
param subnets array

@description('Optional. Tags to apply to all resources.')
param tags object = {}

// Create NSGs only for subnets that have security rules defined.
module nsg '../nsg/main.bicep' = [for subnet in subnets: if (contains(subnet, 'nsgRules')) {
  name: 'nsgDeployment-${subnet.name}'
  scope: resourceGroup() // Explicitly set scope for module deployment
  params: {
    nsgName: '${vnetName}-${subnet.name}-nsg'
    location: location
    securityRules: subnet.nsgRules
    tags: tags
  }
}]

// Create a lookup object for NSG IDs.
// This creates a map of { subnetName: nsgId } for the NSGs that were actually created.
var nsgIdLookup = {
  for (subnet, i) in subnets: if (contains(subnet, 'nsgRules')) {
    '${subnet.name}': nsg[i].outputs.id
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: contains(nsgIdLookup, subnet.name) ? { id: nsgIdLookup[subnet.name] } : null
        privateEndpointNetworkPolicies: (contains(subnet, 'privateEndpointNetworkPoliciesEnabled') && subnet.privateEndpointNetworkPoliciesEnabled) ? 'Enabled' : 'Disabled'
        delegations: contains(subnet, 'delegations') ? subnet.delegations : []
      }
    }]
  }
}

@description('The resource ID of the created Virtual Network.')
output id string = vnet.id

@description('The name of the created Virtual Network.')
output name string = vnet.name

@description('An array of subnet objects, including their IDs and address prefixes.')
output subnets array = [for s in vnet.properties.subnets: {
  name: s.name
  id: s.id
  addressPrefix: s.properties.addressPrefix
}]

@description('A lookup object for subnet resource IDs, keyed by subnet name.')
output subnetIdsByName object = {
  for s in vnet.properties.subnets: {
    '${s.name}': s.id
  }
}
