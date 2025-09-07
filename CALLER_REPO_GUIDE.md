# Caller Repository Structure Guide

This document outlines the recommended structure for a "caller" repository that utilizes the central `reusable-deploy-bicep.yml` workflow. This structure is designed to be logical, scalable, and compatible with GitOps practices, including integration with tools like Argo CD.

## 1. Core Concept

The caller repository contains all the **configuration** for your deployments. It does not contain the Bicep templates themselves (those live in the central framework repository). Instead, it defines *what* to deploy and *how* by providing parameter files and invoking the reusable deployment workflow.

## 2. Recommended Directory Structure

A logical way to organize the repository is by environment and then by application or layer.

```
.
├── .github/
│   └── workflows/
│       └── deploy-my-app.yml       # Example workflow that CALLS the reusable engine
├── environments/
│   ├── dev/
│   │   ├── hub/
│   │   │   └── main.parameters.json  # Parameters for the 'hub' layer in 'dev'
│   │   ├── spoke/
│   │   │   └── main.parameters.json  # Parameters for the 'spoke' layer in 'dev'
│   │   └── app1/
│   │       └── main.parameters.json  # Parameters for 'app1' in 'dev'
│   └── prod/
│       ├── hub/
│       │   └── main.parameters.json
│       ├── spoke/
│       │   └── main.parameters.json
│       └── app1/
│           └── main.parameters.json
└── README.md
```

### Key Components:

*   **`.github/workflows/`**: This directory contains the "caller" workflows. These are specific to your project and are responsible for triggering the reusable deployment workflow with the correct parameters for each environment and layer.
*   **`environments/`**: This is the root directory for all environment-specific configurations.
*   **`environments/<environmentId>/`** (e.g., `dev`, `prod`): Each subdirectory here represents a distinct deployment environment. The name of this folder (`dev`, `prod`) should match the `environmentId` input for the reusable workflow.
*   **`environments/<environmentId>/<stackLayer>/`** (e.g., `hub`, `app1`): Each subdirectory here represents a logical application or infrastructure layer. The name of this folder (`hub`, `app1`) should match the `stackLayer` input.
*   **`main.parameters.json`**: The JSON file containing the specific parameter values for deploying the corresponding Bicep template in that context.

## 3. Example Caller Workflow

Here is an example of what a workflow file like `deploy-my-app.yml` might look like. This workflow triggers the deployment of the `hub` and `spoke` layers for the `dev` environment.

```yaml
# .github/workflows/deploy-my-app.yml

name: 'Deploy Dev Environment'

on:
  push:
    branches:
      - main
    paths:
      - 'environments/dev/**'

jobs:
  deploy-dev-hub:
    uses: YOUR_ORG/bicep-framework-repo/.github/workflows/reusable-deploy-bicep.yml@main
    with:
      frameworkRepo: 'YOUR_ORG/bicep-framework-repo'
      deploymentPrefix: 'my-project'
      environmentId: 'dev'
      stackLayer: 'hub'
      templateFile: 'infra/hub.bicep' # Path to the Bicep file in the framework repo
      parametersFile: 'environments/dev/hub/main.parameters.json' # Path in THIS repo
      deploymentScope: 'subscription'
      location: 'westeurope'
    secrets: inherit

  deploy-dev-spoke:
    needs: deploy-dev-hub
    uses: YOUR_ORG/bicep-framework-repo/.github/workflows/reusable-deploy-bicep.yml@main
    with:
      frameworkRepo: 'YOUR_ORG/bicep-framework-repo'
      deploymentPrefix: 'my-project'
      environmentId: 'dev'
      stackLayer: 'spoke'
      templateFile: 'infra/spoke.bicep'
      parametersFile: 'environments/dev/spoke/main.parameters.json'
      resourceGroupName: 'my-project-dev-spoke-rg'
      deploymentScope: 'resourceGroup'
    secrets: inherit
```

## 4. Integration with Argo CD

This repository structure is fully compatible with Argo CD's App of Apps pattern. While the Bicep deployments are handled by GitHub Actions, Argo CD can manage the Kubernetes-based applications that are deployed *after* the underlying infrastructure is provisioned.

The caller repository can serve as the single source of truth for both infrastructure (via Bicep parameter files) and application deployments (via Argo CD manifests).

### Example with Argo CD Structure:

You can extend the structure to include Argo CD application definitions.

```
.
├── environments/
│   ├── dev/
│   │   ├── hub/
│   │   │   └── main.parameters.json
│   │   └── spoke/
│   │       └── main.parameters.json
│   └── prod/
│       # ...
├── argocd/
│   ├── apps/
│   │   ├── dev/
│   │   │   ├── app1.yaml
│   │   │   └── app2.yaml
│   │   └── prod/
│   │       ├── app1.yaml
│   │       └── app2.yaml
│   └── bootstrap/
│       └── app-of-apps.yaml      # Defines all applications for Argo CD
└── .github/
    └── workflows/
        └── deploy-my-app.yml
```

In this model:
1.  A push to `environments/dev/**` triggers the GitHub Actions workflow to provision Azure infrastructure with Bicep.
2.  Argo CD watches the `argocd/apps/dev/` path in this same repository.
3.  Once the infrastructure is ready, Argo CD can automatically deploy the Kubernetes applications defined in its path.

This creates a powerful, declarative pipeline where both infrastructure and applications are managed through Git.
