@description('Required. The name of the PostgreSQL Flexible Server.')
param serverName string

@description('Required. The location for the server.')
param location string

@description('Required. The administrator login username.')
param administratorLogin string

@description('Required. The administrator login password.')
@secure()
param administratorLoginPassword string

@description('Required. The resource ID of the VNet to link the private DNS zone to.')
param vnetId string

@description('Required. The resource ID of the delegated subnet to deploy the server into.')
param delegatedSubnetId string

@description('Optional. The SKU for the PostgreSQL server.')
param sku object = {
  name: 'Standard_B1ms'
  tier: 'Burstable'
}

@description('Optional. The version of PostgreSQL.')
param postgresVersion string = '14'

@description('Optional. The storage size in GB.')
param storageSizeGB int = 32

@description('Optional. Tags to apply to the resources.')
param tags object = {}

// The private DNS zone name is a fixed format for flexible servers
var privateDnsZoneName = 'private.${serverName}.postgres.database.azure.com'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  tags: tags
}

resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${privateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource psql 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: serverName
  location: location
  tags: tags
  sku: sku
  properties: {
    version: postgresVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storage: {
      storageSizeGB: storageSizeGB
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    network: {
      delegatedSubnetResourceId: delegatedSubnetId
      privateDnsZoneArmResourceId: privateDnsZone.id
    }
  }
  dependsOn: [
    dnsZoneLink
  ]
}

@description('The resource ID of the created PostgreSQL server.')
output id string = psql.id

@description('The name of the created PostgreSQL server.')
output name string = psql.name

@description('The fully qualified domain name of the created PostgreSQL server.')
output fqdn string = psql.properties.fullyQualifiedDomainName
