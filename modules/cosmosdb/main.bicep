@description('Required. The globally unique name of the Cosmos DB account.')
param cosmosAccountName string

@description('Required. The Azure region for the Cosmos DB account.')
param location string

@description('Required. The resource ID of the VNet for private endpoint integration.')
param vnetId string

@description('Required. The resource ID of the subnet to deploy the private endpoint into.')
param subnetId string

@description('Optional. Tags to apply to the resources.')
param tags object = {}

var privateDnsZoneName = 'privatelink.documents.azure.com'
var privateEndpointName = '${cosmosAccountName}-pe'

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosAccountName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB' // for SQL API
  properties: {
    databaseAccountOfferType: 'Standard'
    publicNetworkAccess: 'Disabled'
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
  }
}

// A private DNS zone is needed to resolve the private endpoint.
// This zone is standard for all Cosmos DB SQL endpoints.
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  tags: tags
}

// Link the private DNS zone to the VNet.
resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: guid(privateDnsZone.id, vnetId) // Ensures a unique name for the link
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// Create the private endpoint.
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${cosmosAccountName}-pls-connection'
        properties: {
          privateLinkServiceId: cosmosAccount.id
          groupIds: [ 'Sql' ] // 'Sql' for the SQL API
        }
      }
    ]
  }
}

// Create the DNS A record in the private zone for the private endpoint.
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'cosmosdb-privatelink-documents-azure-com'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

@description('The resource ID of the created Cosmos DB account.')
output id string = cosmosAccount.id

@description('The name of the created Cosmos DB account.')
output name string = cosmosAccount.name

@description('The endpoint of the created Cosmos DB account.')
output endpoint string = cosmosAccount.properties.documentEndpoint
