# Bicep Modules

This file documents the reusable Bicep modules created for this project.

| Module Name | Path | Description |
|---|---|---|
| `Resource Group` | `modules/resourcegroup` | Creates an Azure Resource Group at the subscription level. |
| `Network Security Group (NSG)` | `modules/nsg` | Creates a Network Security Group with a dynamic set of rules. |
| `Virtual Network (VNet)` | `modules/vnet` | Creates a VNet with dynamic subnets and optional NSG association. |
| `NAT Gateway` | `modules/natgateway` | Creates a NAT Gateway and an associated Public IP address for egress. |
| `Key Vault` | `modules/keyvault` | Creates a Key Vault with RBAC, admin assignment, and optional secret creation. |
| `PostgreSQL Flexible Server` | `modules/postgres` | Creates a PostgreSQL Flexible Server in a delegated VNet with private DNS. |
| `Cosmos DB` | `modules/cosmosdb` | Creates a Cosmos DB account with a private endpoint and private DNS integration. |
| `Azure Kubernetes Service (AKS)` | `modules/aks` | Deploys an AKS cluster with AGIC (Greenfield), Key Vault integration, and CSI drivers. |
| `Container Instance (ArgoCD Installer)` | `modules/containerinstance` | Deploys an ACI to run a one-time setup script for ArgoCD. |
| `Jump VM` | `modules/jumpvm` | Deploys a Linux VM with common cloud management tools installed. |
