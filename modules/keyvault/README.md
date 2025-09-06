# Key Vault Module

## Description
This module creates an Azure Key Vault configured for RBAC, assigns an administrator, and can optionally create an initial secret.

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `keyVaultName` | string | Yes | The globally unique name of the Key Vault. |
| `location` | string | Yes | The Azure region for the Key Vault. |
| `adminObjectId` | string | Yes | The object ID of the user, group, or service principal to be granted the 'Key Vault Administrator' role. |
| `adminPrincipalType` | string | Yes | The type of the principal. Allowed: `User`, `Group`, `ServicePrincipal`. Default: `ServicePrincipal`. |
| `secretName` | string | No | The name of an initial secret to create. |
| `secretValue` | securestring | No | The value of the initial secret. Required if `secretName` is provided. |
| `tags` | object | No | Tags to apply to the Key Vault. Default: `{}`. |

## Outputs
| Output | Type | Description |
|---|---|---|
| `id` | string | The resource ID of the created Key Vault. |
| `name` | string | The name of the created Key Vault. |
| `uri` | string | The URI of the created Key Vault. |

## Usage Example
```bicep
// In a parameters file, you would get this from `az ad sp show --id <app-id> --query objectId`
param deployerObjectId string

module kv 'modules/keyvault/main.bicep' = {
  name: 'keyvaultDeployment'
  params: {
    keyVaultName: 'my-unique-kv-12345'
    location: resourceGroup().location
    adminObjectId: deployerObjectId
    adminPrincipalType: 'ServicePrincipal'
    secretName: 'mySslCert'
    secretValue: 'base64-encoded-cert-value'
    tags: {
      environment: 'dev'
    }
  }
}
```
