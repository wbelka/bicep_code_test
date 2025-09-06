@description('Required. The name of the NAT Gateway.')
param natGatewayName string

@description('Required. The location for the NAT Gateway and its Public IP address.')
param location string

@description('Required. The name of the Public IP address to create for the NAT Gateway.')
param publicIpName string

@description('Optional. The SKU for the Public IP address and NAT Gateway. Standard is required for NAT Gateway.')
param skuName string = 'Standard'

@description('Optional. Tags to apply to the resources.')
param tags object = {}

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: publicIpName
  location: location
  sku: {
    name: skuName
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: tags
}

resource natGateway 'Microsoft.Network/natGateways@2023-11-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: skuName
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicIp.id
      }
    ]
  }
  tags: tags
}

@description('The resource ID of the created NAT Gateway.')
output id string = natGateway.id

@description('The resource ID of the created Public IP address.')
output publicIpId string = publicIp.id
