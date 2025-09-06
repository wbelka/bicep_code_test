# TODO

## Phase 1: Project Scaffolding and Resource Group
- [x] Create project structure (`infra`, `modules`)
- [x] Create tracking files (`TODO.md`, `CHANGES.md`, `MODULES.md`)
- [x] Implement `resourcegroup` module
- [x] Create `resources` deployment stack

## Phase 2: Network
- [x] Implement `nsg` module
- [x] Implement `vnet` module
- [x] Implement `natgateway` module
- [x] Create `network` deployment stack (including two VNets and peering)

## Phase 3: Application Services
- [x] Implement `keyvault` module
- [x] Implement `postgres` module
- [x] Implement `cosmosdb` module
- [x] Implement `aks` module (with AGIC and CSI drivers)
- [x] Implement `containerinstance` module for ArgoCD setup
- [x] (Optional) Implement `jumpvm` module
- [x] Create `app` deployment stack

## Phase 4: CI/CD
- [x] Create reusable GitHub Action for deploying a Bicep stack
- [x] Create main GitHub Action workflow to deploy all stacks in sequence
