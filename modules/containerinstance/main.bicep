@description('Required. The location for the container instance.')
param location string

@description('Required. The resource ID of the AKS cluster.')
param aksClusterId string

@description('Required. The name of the AKS cluster.')
param aksClusterName string

@description('Required. The name of the resource group containing the AKS cluster.')
param resourceGroupName string

@description('Required. The Git repository URL for ArgoCD to track.')
param argocdRepoUrl string

@description('Required. The private SSH key for ArgoCD to access the repository.')
@secure()
param argocdGitSshKey string

@description('Optional. Tags to apply to the resources.')
param tags object = {}

var containerGroupName = 'argocd-installer-aci'
var containerName = 'installer'
var aksClusterUserRoleId = '4f8d02c7-c151-4000-9c71-c2a606b847df'

// This script will be base64 encoded and run inside the container.
var startupScript = '''
#!/bin/bash
set -e
echo "Starting ArgoCD setup script..."

# 1. Install Helm
echo "Installing Helm..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 2. Login to Azure and get AKS credentials
echo "Getting AKS credentials for cluster ${AKS_NAME} in RG ${RG_NAME}..."
az login --identity
az aks get-credentials --resource-group "${RG_NAME}" --name "${AKS_NAME}" --overwrite-existing

# 3. Install ArgoCD
echo "Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd --namespace argocd --version 5.51.2

# 4. Wait for ArgoCD server to be ready
echo "Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=5m

# 5. Configure repository
echo "Configuring ArgoCD repository at ${ARGOCD_REPO_URL}..."
# The ARGOCD_GIT_SSH_KEY is passed as a secure environment variable.
# We create a Kubernetes secret that ArgoCD is configured to use for repository access.
cat <<EOF | kubectl apply -n argocd -f -
apiVersion: v1
kind: Secret
metadata:
  name: private-repo-creds
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: ${ARGOCD_REPO_URL}
  sshPrivateKey: |
    ${ARGOCD_GIT_SSH_KEY}
EOF

echo "ArgoCD setup script completed successfully."
'''

resource aks 'Microsoft.ContainerService/managedClusters@2024-02-01' existing = {
  name: aksClusterName
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerGroupName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    containers: [
      {
        name: containerName
        image: 'mcr.microsoft.com/azure-cli:2.53.0'
        command: [
          '/bin/bash'
          '-c'
          'echo \'${base64(startupScript)}\' | base64 -d | bash'
        ]
        environmentVariables: [
          {
            name: 'RG_NAME'
            value: resourceGroupName
          }
          {
            name: 'AKS_NAME'
            value: aksClusterName
          }
          {
            name: 'ARGOCD_REPO_URL'
            value: argocdRepoUrl
          }
          {
            name: 'ARGOCD_GIT_SSH_KEY'
            secureValue: argocdGitSshKey
          }
        ]
        resources: {
          requests: {
            cpu: 1
            memoryInGB: 2
          }
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'OnFailure'
  }
}

resource aksRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: aks
  name: guid(containerGroup.id, aks.id, aksClusterUserRoleId)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', aksClusterUserRoleId)
    principalId: containerGroup.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

@description('The resource ID of the created Container Group.')
output id string = containerGroup.id
