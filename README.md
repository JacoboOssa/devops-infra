# DevOps Infrastructure for Microservices

This repository contains the infrastructure as code (Terraform) and CI/CD pipeline for deploying a microservices-based application to Azure.

## Project Structure

```
├── azure-pipelines.yml        # Azure DevOps pipeline definition
├── docker.tf                  # Docker resources definitions
├── environments/              # Environment-specific configurations
│   ├── preprod/               # Pre-production environment
│   ├── prod/                  # Production environment
│   └── test/                  # Test environment
└── modules/                   # Reusable Terraform modules
    ├── acr/                   # Azure Container Registry module
    ├── container_app/         # Azure Container App module
    └── log_analytics/         # Log Analytics module
```

## Infrastructure Components

This project deploys the following Azure resources:

- **Azure Container Registry (ACR)**: For storing and managing Docker images with Basic SKU
- **Azure Container Apps**: For running microservices in a serverless environment with auto-scaling
- **Azure Container App Environment**: Shared hosting environment for Container Apps
- **Azure API Management** : For API gateway capabilities and management
- **Azure Resource Group**: For logical grouping of resources
- **Azure Secrets**: For securely storing sensitive information such as registry credentials

### Microservices Architecture

The infrastructure supports the following microservices:

1. **Auth API**: Authentication service built with Go
   - External ingress enabled
   - Auto-scaling (1-3 replicas)

2. **Users API**: User management service built with Java
   - External ingress enabled
   - Auto-scaling (1-3 replicas)

3. **Todos API**: Task management service built with Node.js
   - External ingress enabled
   - Auto-scaling (1-3 replicas)
   - Integrates with Redis for caching

4. **Frontend**: Web user interface built with Node.js
   - External ingress enabled
   - Auto-scaling (1-3 replicas)

5. **Redis**: In-memory data store used for caching and pub/sub messaging
   - Internal access only (no external ingress)
   - Single replica deployment

6. **Log Message Processor**: Service for processing log messages built with Python
   - Internal access only (no external ingress)
   - Single replica deployment
   - Subscribes to Redis channels for log processing

### Networking & Communication

- Services communicate internally via Container App networking
- External services are exposed via ingress configurations
- Service-to-service communication uses internal DNS names
- Redis operates as an internal service for secure communications

## Environments

The infrastructure is deployed to three environments:

- **Test**: For testing new features and changes
- **Pre-production**: For final validation before production
- **Production**: The live environment

Each environment has its own configuration variables defined in the respective `terraform.tfvars` files.

## CI/CD Pipeline

The project includes an Azure DevOps pipeline (`azure-pipelines.yml`) that automates the deployment process.

### Pipeline Features

- **Change Detection**: Automatically detects which files have changed and only deploys to affected environments
- **Manual Deployment Options**: Allows forced deployment to specific environments using parameters
- **Multi-Stage Deployment**: Ensures proper progression from test → pre-prod → production
- **Validation**: Includes Terraform validation and formatting checks

### Pipeline Stages

1. **Detect Changes**: Determines which files have changed in the commit
2. **Validate**: Validates Terraform configuration
3. **Test**: Deploys to the test environment (if changes detected or manually triggered)
4. **PreProd**: Deploys to the pre-production environment (if changes detected or manually triggered)
5. **Prod**: Deploys to the production environment (if changes detected or manually triggered)

### Deployment Process

Each environment deployment consists of:

1. **Plan**: Creates a Terraform plan and saves it as an artifact
2. **Deploy**: Applies the Terraform plan to the environment

### Pipeline Parameters

The pipeline supports the following parameters for manual deployments:

- `deployTest`: Force deployment to Test environment
- `deployPreProd`: Force deployment to Pre-production environment
- `deployProd`: Force deployment to Production environment

## Resource Specifications

### Container Apps
- **CPU Allocation**: 0.5 vCPU per container
- **Memory Allocation**: 1Gi per container
- **Revision Mode**: Single (for controlled updates)
- **Auto-scaling Rules**: Based on HTTP traffic and CPU usage

### Container Registry
- **SKU**: Basic tier
- **Admin Access**: Enabled for simplified deployment
- **Name**: Generated with a random suffix for uniqueness

### Log Analytics
- **SKU**: PerGB2018 pricing tier
- **Retention**: 30 days for log data

## Getting Started

1. Clone this repository
2. Configure your Azure service connection in Azure DevOps
3. Update the `terraform.tfvars` files in each environment directory with your specific values
4. Run the pipeline

## Prerequisites

- Azure DevOps account
- Azure subscription
- Service principal with appropriate permissions
- Terraform installed locally for development (v1.7.0+)

## Notes

- The pipeline uses Terraform `1.7.0`
- State is stored in Azure Storage Account
- The pipeline automatically detects changes to ensure efficient deployments
- API Management resources are defined but commented out, ready for future implementation