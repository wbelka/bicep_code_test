@description('The scope of this deployment is the subscription.')
targetScope = 'subscription'

@description('The prefix for all resources in this deployment.')
param prefix string = 'mycorp'

@description('The environment for this deployment (e.g., dev, tst, prd).')
param environment string = 'dev'

@description('The Azure region for the resources.')
param location string = 'westeurope'

var resourceGroupName = '${prefix}-rg-${environment}'
var tags = {
  environment: environment
  project: prefix
}

module rg '../../modules/resourcegroup/main.bicep' = {
  name: 'resourceGroupDeployment'
  params: {
    resourceGroupName: resourceGroupName
    location: location
    tags: tags
  }
}

output resourceGroupId string = rg.outputs.resourceGroupId
output resourceGroupName string = rg.outputs.resourceGroupName
output resourceGroupLocation string = rg.outputs.resourceGroupLocation
