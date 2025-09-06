@description('The Azure region for the network resources.')
param location string

@description('The prefix for all resources in this deployment.')
param prefix string = 'mycorp'

@description('The environment for this deployment (e.g., dev, tst, prd).')
param environment string = 'dev'

@description('Tags to apply to all resources.')
param tags object = {}

@description('The resource ID of the Hub VNet to peer with.')
param hubVnetId string

@description('The name of the Hub VNet.')
param hubVnetName string

@description('The name of the resource group where the Hub VNet is deployed.')
param hubResourceGroupName string

@description('The private IP of the Azure Firewall in the hub. If empty, no UDR will be created.')
param firewallPrivateIp string = ''

@description('The address prefixes for the Spoke VNet.')
param spokeVnetAddressPrefixes array

@description('The subnet configurations for the Spoke VNet.')
param spokeSubnets array

// --- Resource Naming ---
var spokeVnetName = '${prefix}-vnet-spoke-${environment}'
var routeTableName = '${prefix}-rt-spoke-to-hub-${environment}'
var spokeToHubPeeringName = '${spokeVnetName}-to-${hubVnetName}'
var hubToSpokePeeringName = '${hubVnetName}-to-${spokeVnetName}'


// --- Resources ---

// Route table to direct all traffic to the Azure Firewall in the hub
resource routeTable 'Microsoft.Network/routeTables@2023-11-01' = if (!empty(firewallPrivateIp)) {
  name: routeTableName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp // Corrected to use the string parameter directly
        }
      }
    ]
  }
}

// Add route table to each subnet definition if firewall is deployed
var subnetsWithUdr = [for subnet in spokeSubnets: {
  name: subnet.name
  addressPrefix: subnet.addressPrefix
  nsgRules: subnet.nsgRules
  privateEndpointNetworkPoliciesEnabled: contains(subnet, 'privateEndpointNetworkPoliciesEnabled') ? subnet.privateEndpointNetworkPoliciesEnabled : null
  delegations: contains(subnet, 'delegations') ? subnet.delegations : []
  // Corrected to use routeTableId as expected by the module
  routeTableId: routeTable.id
}]

// Spoke Virtual Network
module spokeVnet '../../modules/vnet/main.bicep' = {
  name: 'spokeVnetDeployment'
  params: {
    vnetName: spokeVnetName
    location: location
    addressPrefixes: spokeVnetAddressPrefixes
    subnets: !empty(firewallPrivateIp) ? subnetsWithUdr : spokeSubnets
    tags: tags
  }
}

// --- VNet Peering ---

// Peering from Spoke to Hub
resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: spokeVnet
  name: spokeToHubPeeringName
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true // Allows spoke to use gateway in hub
    remoteVirtualNetwork: {
      id: hubVnetId
    }
  }
}

// Peering from Hub to Spoke
resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  name: hubToSpokePeeringName
  scope: resourceGroup(hubResourceGroupName)
  parent: resourceId(hubResourceGroupName, 'Microsoft.Network/virtualNetworks', hubVnetName)
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true // Allows spoke to use gateway in hub
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnet.outputs.id
    }
  }
}


// --- Outputs ---

output spokeVnetId string = spokeVnet.outputs.id
output spokeVnetName string = spokeVnetName
output subnetIdsByName object = spokeVnet.outputs.subnetIdsByName
output appGwSubnetId string = spokeVnet.outputs.subnetIdsByName.AppGwSubnet
output aksSubnetId string = spokeVnet.outputs.subnetIdsByName.AksSubnet
output dbSubnetId string = spokeVnet.outputs.subnetIdsByName.DbSubnet
