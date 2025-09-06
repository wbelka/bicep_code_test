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

@description('Boolean to decide whether to deploy Azure Firewall.')
param deployFirewall bool = false

@description('The address prefixes for the Hub VNet.')
param hubVnetAddressPrefixes array

@description('The subnet configurations for the Hub VNet.')
param hubSubnets array

// --- Resource Naming ---
var hubVnetName = '${prefix}-vnet-hub-${environment}'
var natGatewayName = '${prefix}-nat-${environment}'
var publicIpNameForNat = '${prefix}-pip-nat-${environment}'
var publicIpNameForFirewall = '${prefix}-pip-fw-${environment}'
var firewallName = '${prefix}-fw-${environment}'

// This variable injects the adminSourceAddressPrefix into the hubSubnets parameter,
// replacing any rule where the sourceAddressPrefix is 'ADMIN_SOURCE_IP'.
var processedHubSubnets = [for subnet in hubSubnets: {
  name: subnet.name
  addressPrefix: subnet.addressPrefix
  nsgRules: [for rule in subnet.nsgRules: {
    name: rule.name
    priority: rule.priority
    direction: rule.direction
    access: rule.access
    protocol: rule.protocol
    sourcePortRange: rule.sourcePortRange
    sourceAddressPrefix: rule.sourceAddressPrefix == 'ADMIN_SOURCE_IP' ? adminSourceAddressPrefix : rule.sourceAddressPrefix
    destinationPortRange: rule.destinationPortRange
  }]
}]

// AzureFirewallSubnet must have this exact name and a prefix of at least /26.
var firewallSubnet = {
  name: 'AzureFirewallSubnet'
  addressPrefix: '10.30.1.0/26'
  nsgRules: [] // No NSG on firewall subnet
}

// --- Module & Resource Deployments ---

// Hub Virtual Network
module hubVnet '../../modules/vnet/main.bicep' = {
  name: 'hubVnetDeployment'
  params: {
    vnetName: hubVnetName
    location: location
    addressPrefixes: hubVnetAddressPrefixes
    // Conditionally add Firewall subnet
    subnets: deployFirewall ? union(processedHubSubnets, [firewallSubnet]) : processedHubSubnets
    tags: tags
  }
}

// NAT Gateway for egress, to be used by the Firewall
module natGateway '../../modules/natgateway/main.bicep' = if (deployFirewall) {
  name: 'natGatewayDeployment'
  params: {
    natGatewayName: natGatewayName
    publicIpName: publicIpNameForNat
    location: location
    tags: tags
  }
}

// Public IP for Firewall
resource publicIpForFirewall 'Microsoft.Network/publicIPAddresses@2023-11-01' = if (deployFirewall) {
  name: publicIpNameForFirewall
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
  tags: tags
}

// Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2023-11-01' = if (deployFirewall) {
  name: firewallName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: 'firewall-ip-config'
        properties: {
          subnet: {
            id: hubVnet.outputs.subnetIdsByName[firewallSubnet.name]
          }
          publicIPAddress: {
            id: publicIpForFirewall.id
          }
        }
      }
    ]
  }
}

// Associate NAT Gateway with the Firewall subnet for egress.
// This resource updates the subnet created by the vnet module to attach the NAT Gateway.
resource firewallSubnetNatAssociation 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = if (deployFirewall) {
  parent: hubVnet
  name: firewallSubnet.name
  properties: {
    addressPrefix: firewallSubnet.addressPrefix
    natGateway: {
      id: natGateway.outputs.id
    }
    // The vnet module associates an NSG by default, but AzureFirewallSubnet cannot have an NSG.
    // We explicitly set the networkSecurityGroup to null to ensure compliance.
    networkSecurityGroup: null
  }
}

// --- Outputs ---

output hubVnetId string = hubVnet.outputs.id
output location string = location
output hubVnetName string = hubVnetName
output firewallPrivateIp string = deployFirewall ? firewall.properties.ipConfigurations[0].properties.privateIPAddress : ''
output jumpServerSubnetId string = hubVnet.outputs.subnetIdsByName.JumpServerSubnet
