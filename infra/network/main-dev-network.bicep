@description('The name of the resource group where the network resources will be deployed.')
param resourceGroupName string

@description('The Azure region for the network resources.')
param location string

@description('The prefix for all resources in this deployment.')
param prefix string = 'mycorp'

@description('The environment for this deployment (e.g., dev, tst, prd).')
param environment string = 'dev'

@description('Tags to apply to all resources.')
param tags object = {}

@description('The address prefix for the admin user\'s machine to allow SSH/RDP access.')
param adminSourceAddressPrefix string

// --- Resource Naming ---
var privateVnetName = '${prefix}-vnet-private-${environment}'
var publicVnetName = '${prefix}-vnet-public-${environment}'
var natGatewayName = '${prefix}-nat-${environment}'
var publicIpNameForNat = '${prefix}-pip-nat-${environment}'
var privateToPublicPeeringName = '${privateVnetName}-to-${publicVnetName}'
var publicToPrivatePeeringName = '${publicVnetName}-to-${privateVnetName}'

// --- Subnet Definitions ---
var privateSubnets = [
  {
    name: 'AksSubnet'
    addressPrefix: '10.20.0.0/24'
    nsgRules: [] // AKS NSG rules are often managed by AKS itself or can be complex. Leaving empty for now.
  }
  {
    name: 'AppGwSubnet'
    addressPrefix: '10.20.1.0/24'
    nsgRules: [
      {
        name: 'Allow_AppGw_Mgmt'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        sourceAddressPrefix: 'GatewayManager'
        destinationPortRange: '65200-65535'
      }
      {
        name: 'Allow_Web'
        priority: 200
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        sourceAddressPrefix: 'Internet'
        destinationPortRange: [ '80', '443' ]
      }
    ]
  }
  {
    name: 'DbSubnet'
    addressPrefix: '10.20.2.0/24'
    privateEndpointNetworkPoliciesEnabled: false // Must be false for delegated subnets
    delegations: [
      {
        name: 'postgresql-delegation'
        properties: {
          serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
        }
      }
    ]
    nsgRules: [
      {
        name: 'Allow_Postgres'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        sourceAddressPrefix: '10.20.0.0/24' // From AKS Subnet
        destinationPortRange: '5432'
      }
    ]
  }
  {
    name: 'ManagementSubnet'
    addressPrefix: '10.20.3.0/27'
    nsgRules: [
      {
        name: 'Allow_Admin_SSH'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        sourceAddressPrefix: adminSourceAddressPrefix
        destinationPortRange: '22'
      }
    ]
  }
]

var publicSubnets = [
  {
    name: 'JumpServerSubnet'
    addressPrefix: '10.30.0.0/27'
    nsgRules: [
      {
        name: 'Allow_Admin_SSH'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        sourceAddressPrefix: adminSourceAddressPrefix
        destinationPortRange: '22'
      }
    ]
  }
]

// --- Module Deployments ---

module natGateway '../../modules/natgateway/main.bicep' = {
  name: 'natGatewayDeployment'
  params: {
    natGatewayName: natGatewayName
    publicIpName: publicIpNameForNat
    location: location
    tags: tags
  }
}

module privateVnet '../../modules/vnet/main.bicep' = {
  name: 'privateVnetDeployment'
  params: {
    vnetName: privateVnetName
    location: location
    addressPrefixes: [ '10.20.0.0/22' ]
    subnets: privateSubnets
    tags: tags
  }
}

module publicVnet '../../modules/vnet/main.bicep' = {
  name: 'publicVnetDeployment'
  params: {
    vnetName: publicVnetName
    location: location
    addressPrefixes: [ '10.30.0.0/24' ]
    subnets: publicSubnets
    tags: tags
  }
}

// --- Resource Configurations ---

// Associate NAT Gateway with the AKS subnet
resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: privateVnet
  name: 'AksSubnet'
  properties: {
    addressPrefix: '10.20.0.0/24'
    natGateway: {
      id: natGateway.outputs.id
    }
  }
}

// VNet Peering
resource privateToPublicPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: privateVnet
  name: privateToPublicPeeringName
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: publicVnet.outputs.id
    }
  }
}

resource publicToPrivatePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: publicVnet
  name: publicToPrivatePeeringName
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: privateVnet.outputs.id
    }
  }
}

// --- Outputs ---

output privateVnetId string = privateVnet.outputs.id
output privateSubnetIdsByName object = privateVnet.outputs.subnetIdsByName
output appGwSubnetId string = privateVnet.outputs.subnetIdsByName.AppGwSubnet
output aksSubnetId string = privateVnet.outputs.subnetIdsByName.AksSubnet
output dbSubnetId string = privateVnet.outputs.subnetIdsByName.DbSubnet
output jumpServerSubnetId string = publicVnet.outputs.subnetIdsByName.JumpServerSubnet
