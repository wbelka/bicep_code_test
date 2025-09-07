@description('The location for the application resources.')
param location string

@description('The prefix for all resources in this deployment.')
param prefix string = 'mycorp'

@description('The environment for this deployment (e.g., dev, tst, prd).')
param environment string = 'dev'

@description('Tags to apply to all resources.')
param tags object = {}

// --- Network Inputs ---
@description('The resource ID of the Hub VNet.')
param hubVnetId string

@description('The resource ID of the Spoke VNet.')
param spokeVnetId string

@description('The resource ID of the database subnet.')
param dbSubnetId string

@description('The resource ID of the AKS cluster subnet.')
param clusterSubnetId string

@description('The resource ID of the Application Gateway subnet.')
param appGwSubnetId string

@description('The resource ID of the Jump Server subnet.')
param jumpServerSubnetId string

// --- Secret Inputs ---
@description('The object ID of the principal to be granted Key Vault Administrator permissions.')
param keyVaultAdminObjectId string

@description('The administrator login for the PostgreSQL server.')
param postgresAdminLogin string

@description('The administrator password for the PostgreSQL server.')
@secure()
param postgresAdminPassword string

@description('The Base64-encoded PFX value for the SSL certificate to be stored in Key Vault.')
@secure()
param sslCertSecretValue string

@description('The Git repository URL for ArgoCD.')
param argocdRepoUrl string

@description('The private SSH key for ArgoCD to access the repository.')
@secure()
param argocdGitSshKey string

@description('Optional. Set to true to deploy the Jump VM.')
param deployJumpVm bool = false

@description('Optional. The public SSH key for the Jump VM administrator.')
param jumpVmSshPublicKey string = ''

// --- Resource Naming ---
var keyVaultName = '${prefix}-kv-${environment}'
var postgresServerName = '${prefix}-psql-${environment}'
var cosmosAccountName = '${prefix}-cosmos-${environment}'
var aksClusterName = '${prefix}-aks-${environment}'
var jumpVmName = '${prefix}-jumpvm-${environment}'

// --- Module Deployments ---

module keyvault '../../modules/keyvault/main.bicep' = {
  name: 'keyvaultDeployment'
  params: {
    keyVaultName: keyVaultName
    location: location
    adminObjectId: keyVaultAdminObjectId
    adminPrincipalType: 'ServicePrincipal' // Assuming deployment is run by a Service Principal
    secretName: 'ssl-certificate'
    secretValue: sslCertSecretValue
    tags: tags
  }
}

module postgres '../../modules/postgres/main.bicep' = {
  name: 'postgresDeployment'
  params: {
    serverName: postgresServerName
    location: location
    administratorLogin: postgresAdminLogin
    administratorLoginPassword: postgresAdminPassword
    vnetId: spokeVnetId
    delegatedSubnetId: dbSubnetId
    tags: tags
  }
}

module cosmosdb '../../modules/cosmosdb/main.bicep' = {
  name: 'cosmosdbDeployment'
  params: {
    cosmosAccountName: cosmosAccountName
    location: location
    vnetId: spokeVnetId
    subnetId: dbSubnetId
    tags: tags
  }
}

module aks '../../modules/aks/main.bicep' = {
  name: 'aksDeployment'
  params: {
    clusterName: aksClusterName
    location: location
    dnsPrefix: aksClusterName
    clusterSubnetId: clusterSubnetId
    appGatewaySubnetId: appGwSubnetId
    keyVaultId: keyvault.outputs.id
    tags: tags
  }
}

module argoInstaller '../../modules/containerinstance/main.bicep' = {
  name: 'argoInstallerDeployment'
  params: {
    location: location
    aksClusterId: aks.outputs.id
    aksClusterName: aks.outputs.name
    resourceGroupName: resourceGroup().name
    argocdRepoUrl: argocdRepoUrl
    argocdGitSshKey: argocdGitSshKey
    tags: tags
  }
}

module jumpvm '../../modules/jumpvm/main.bicep' = if (deployJumpVm) {
  name: 'jumpVmDeployment'
  params: {
    vmName: jumpVmName
    location: location
    subnetId: jumpServerSubnetId
    adminSshPublicKey: jumpVmSshPublicKey
    tags: tags
  }
}

// --- Outputs ---
output keyVaultId string = keyvault.outputs.id
output keyVaultName string = keyvault.outputs.name
output postgresServerId string = postgres.outputs.id
output postgresServerFqdn string = postgres.outputs.fqdn
output cosmosAccountId string = cosmosdb.outputs.id
output cosmosAccountEndpoint string = cosmosdb.outputs.endpoint
output aksClusterId string = aks.outputs.id
output aksClusterName string = aks.outputs.name
output aksClusterPrincipalId string = aks.outputs.principalId
output jumpVmPublicIp string = deployJumpVm ? jumpvm.outputs.publicIpAddress : ''
