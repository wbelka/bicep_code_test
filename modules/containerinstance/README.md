# Container Instance (ArgoCD Installer) Module

## Description
This module deploys an Azure Container Instance (ACI) designed to perform a one-time setup of ArgoCD on a target AKS cluster. It uses a startup script to install and configure ArgoCD.

## Key Features
- Deploys an ACI with a system-assigned managed identity.
- Assigns the ACI identity the `Azure Kubernetes Service Cluster User Role` on the target AKS cluster, allowing it to authenticate.
- Runs a startup script inside the container (`mcr.microsoft.com/azure-cli`) that:
  - Installs Helm.
  - Logs into Azure using the managed identity.
  - Fetches credentials for the target AKS cluster.
  - Installs the ArgoCD Helm chart.
  - Creates a Kubernetes secret in the `argocd` namespace containing Git repository credentials (URL and a private SSH key). This secret is labeled for ArgoCD to automatically discover and use it.
- The ACI is set to `RestartPolicy: OnFailure`, meaning it will run once and not restart on successful completion.

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `location` | string | Yes | The Azure region for the container instance. |
| `aksClusterId` | string | Yes | The resource ID of the target AKS cluster. |
| `aksClusterName` | string | Yes | The name of the target AKS cluster. |
| `resourceGroupName` | string | Yes | The name of the resource group containing the AKS cluster. |
| `argocdRepoUrl` | string | Yes | The Git repository URL for ArgoCD to track (e.g., `git@github.com:user/repo.git`). |
| `argocdGitSshKey` | securestring | Yes | The private SSH key for ArgoCD to access the repository. |
| `tags` | object | No | Tags to apply to the resources. Default: `{}`. |

## Outputs
| Output | Type | Description |
|---|---|---|
| `id` | string | The resource ID of the created Container Group. |

## Usage Example
```bicep
// Assumes an AKS cluster has been deployed and its details are available.
param aksClusterId string
param aksClusterName string
param resourceGroupName string
param argoRepoUrl string
param argoSshKey string // This should be a secure parameter

module argoInstaller 'modules/containerinstance/main.bicep' = {
  name: 'argoInstallerDeployment'
  params: {
    location: resourceGroup().location
    aksClusterId: aksClusterId
    aksClusterName: aksClusterName
    resourceGroupName: resourceGroupName
    argocdRepoUrl: argoRepoUrl
    argocdGitSshKey: argoSshKey
  }
}
```
