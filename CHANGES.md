# Changelog

All significant changes to this project will be documented in this file.

## 2025-09-06

### Automation and Finalization
- Implemented `containerinstance` module to automate ArgoCD setup.
- Implemented optional `jumpvm` module.
- Created reusable GitHub Actions workflow for Bicep stack deployment.
- Created main GitHub Actions workflow to orchestrate the deployment of all layers.

### Application Services
- Implemented `keyvault` Bicep module.
- Updated `vnet` module to support subnet delegation.
- Implemented `postgres` Bicep module for Flexible Server, including private DNS zone integration.
- Implemented `cosmosdb` Bicep module with private endpoint integration.
- Implemented `aks` Bicep module using AGIC greenfield deployment.
- Finalized the `app` deployment stack to orchestrate all application services including AKS.

### Network
- Implemented `nsg`, `vnet`, and `natgateway` Bicep modules.
- Created the main `network` deployment stack.
- The stack deploys a private VNet, a public VNet, a NAT Gateway for egress, and configures peering between the VNets.

### Infrastructure & Scaffolding
- Initialized project structure.
- Created tracking files: `TODO.md`, `CHANGES.md`, `MODULES.md`.
- Implemented the `resourcegroup` Bicep module.
- Created the initial `resources` deployment stack to consume the `resourcegroup` module.
