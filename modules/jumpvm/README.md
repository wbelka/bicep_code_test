# Jump VM Module

## Description
This module deploys a Linux Virtual Machine (Ubuntu 22.04-LTS) to serve as a "jump box" or management server for the environment. It comes pre-configured with common cloud and Kubernetes command-line tools.

## Key Features
- Deploys a VM into a specified subnet.
- Assigns a static Public IP address for external access.
- Uses SSH public key authentication.
- A Custom Script Extension installs the following tools on first boot:
  - Azure CLI (`az`)
  - `kubectl`
  - `helm`
  - ArgoCD CLI (`argocd`)

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `vmName` | string | Yes | The name for the Virtual Machine. |
| `location` | string | Yes | The Azure region for the VM and its resources. |
| `subnetId` | string | Yes | The resource ID of the subnet to deploy the VM into. |
| `adminUsername` | string | No | The username for the VM administrator. Default: `azureuser`. |
| `adminSshPublicKey` | string | Yes | The public SSH key for the VM administrator for authentication. |
| `vmSize` | string | No | The size of the VM. Default: `Standard_B1s`. |
| `tags` | object | No | Tags to apply to the resources. Default: `{}`. |

## Outputs
| Output | Type | Description |
|---|---|---|
| `id` | string | The resource ID of the created Virtual Machine. |
| `publicIpAddress` | string | The Public IP address of the created Virtual Machine. |

## Usage Example
```bicep
// Assumes a subnet 'jumpSubnet' already exists.
param jumpSubnetId string
param sshPublicKey string // This should be a secure parameter

module jumpVm 'modules/jumpvm/main.bicep' = {
  name: 'jumpVmDeployment'
  params: {
    vmName: 'my-jump-vm'
    location: resourceGroup().location
    subnetId: jumpSubnetId
    adminSshPublicKey: sshPublicKey
  }
}
```
