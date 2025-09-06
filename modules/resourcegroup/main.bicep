targetScope = 'subscription'

@description('Required. The name of the resource group to create.')
param resourceGroupName string

@description('Required. The Azure region where the resource group should be created (e.g., \'eastus\', \'westeurope\').')
param location string

@description('Optional. Tags to apply to the resource group.')
param tags object = {}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

@description('The full resource ID of the created resource group.')
output resourceGroupId string = rg.id

@description('The name of the created resource group.')
output resourceGroupName string = rg.name

@description('The location of the created resource group.')
output resourceGroupLocation string = rg.location
