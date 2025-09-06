# Azure Bicep Deployment Framework

This project contains a modular and reusable Bicep framework for deploying a complete application infrastructure on Azure. The deployment is orchestrated via GitHub Actions and is broken down into three main layers: resources, network, and application services.

## Project Structure

- **`.github/workflows/`**: Contains the GitHub Actions workflows for CI/CD.
  - `deploy.yml`: The main workflow that orchestrates the deployment of all layers.
  - `reusable-deploy-bicep.yml`: A reusable workflow for deploying a single Bicep stack.
- **`infra/`**: Contains the main Bicep files for each deployment layer.
  - `resources/`: Deploys the foundational resource group.
  - `network/`: Deploys all networking components (VNet, Subnets, NSGs, NAT Gateway, Peering).
  - `app/`: Deploys all application services (Key Vault, Databases, AKS, etc.).
- **`modules/`**: Contains all the reusable, atomic Bicep modules. Each module has its own `README.md` explaining its usage.

## How to Deploy

1.  **Prerequisites**:
    - An Azure subscription.
    - An Azure Service Principal with `Contributor` and `User Access Administrator` roles at the subscription level.
    - Fork this repository into your GitHub account.

2.  **Configure GitHub Secrets**:
    Navigate to your repository's `Settings > Secrets and variables > Actions` and create the following secrets:

    | Secret Name | Description | Example Value |
    |---|---|---|
    | `AZURE_CLIENT_ID` | The Client ID (or App ID) of your Azure Service Principal. | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
    | `AZURE_TENANT_ID` | The Tenant ID of your Azure subscription. | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
    | `AZURE_SUBSCRIPTION_ID` | The ID of your Azure subscription. | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
    | `AZURE_CLIENT_SECRET` | The secret value for your Azure Service Principal. | `~xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |
    | `POSTGRES_ADMIN_LOGIN` | The desired admin username for the PostgreSQL server. | `psqladmin` |
    | `POSTGRES_ADMIN_PASSWORD`| The password for the PostgreSQL admin user. | `A-Very-Complex-Password!123` |
    | `JUMP_VM_SSH_PUBLIC_KEY`| The public part of your SSH key for accessing the Jump VM. | `ssh-rsa AAAA...` |
    | `ARGOCD_GIT_SSH_KEY`   | The private part of an SSH key that has read access to your ArgoCD Git repo. | `-----BEGIN OPENSSH PRIVATE KEY-----\n...` |
    | `AZURE_CLIENT_ID_OBJECT_ID` | The **Object ID** of your Azure Service Principal. Needed for Key Vault admin access. | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
    | `ADMIN_SOURCE_ADDRESS_PREFIX` | Your local machine's public IP address with a /32 suffix, for SSH access to the Jump VM. | `123.45.67.89/32` |
    | `SSL_CERT_SECRET_VALUE`| A placeholder for a certificate value you might want to store in Key Vault. | `your-cert-value` |
    | `ARGOCD_REPO_URL` | The SSH URL of the Git repository ArgoCD should sync with. | `git@github.com:your-user/your-app-configs.git` |

3.  **Run the Workflow**:
    - Go to the `Actions` tab in your GitHub repository.
    - Select the `Deploy Azure Infrastructure` workflow.
    - Click `Run workflow` and then `Run workflow` again. The deployment will begin.

## Project Evolution

For a detailed log of all changes and implemented features, see `CHANGES.md`.
For a list of all available Bicep modules, see `MODULES.md`.
For the original project plan, see `TODO.md`.
