@description('Required. The name of the Network Security Group.')
param nsgName string

@description('Required. The location for the Network Security Group.')
param location string

@description('Optional. An array of security rule objects to create in the NSG.')
param securityRules array = []

@description('Optional. Tags to apply to the NSG.')
param tags object = {}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [for rule in securityRules: {
      name: rule.name
      properties: {
        description: rule.description
        protocol: rule.protocol
        sourcePortRange: contains(rule, 'sourcePortRange') ? rule.sourcePortRange : '*'
        destinationPortRange: rule.destinationPortRange
        sourceAddressPrefix: contains(rule, 'sourceAddressPrefix') ? rule.sourceAddressPrefix : '*'
        destinationAddressPrefix: contains(rule, 'destinationAddressPrefix') ? rule.destinationAddressPrefix : '*'
        access: rule.access
        priority: rule.priority
        direction: rule.direction
      }
    }]
  }
}

@description('The resource ID of the created Network Security Group.')
output id string = nsg.id

@description('The name of the created Network Security Group.')
output name string = nsg.name
