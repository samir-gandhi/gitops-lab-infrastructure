# Infrastructure Deployment Guide

This guide covers the deployment of the GitOps Lab infrastructure components.

## Prerequisites

- Kubernetes cluster access
- Helm 3.x installed
- kubectl configured
- AWS CLI configured (for S3 state backend)

## Deployment Process

### Local Development

1. **Configure Environment**:
   ```bash
   cp secretstemplate localsecrets
   # Edit localsecrets with your values
   source localsecrets
   ```

2. **Deploy Infrastructure**:
   ```bash
   ./scripts/deploy-infrastructure.sh
   ```

### CI/CD Deployment

Infrastructure is automatically deployed via GitHub Actions when changes are pushed to:
- `infrastructure/`
- `server-profiles/`
- `.github/workflows/infrastructure-deploy.yml`

## State Management

Terraform state is stored in AWS S3. The state key structure is:
- Production: `infrastructure-state/prod/terraform.tfstate`
- QA: `infrastructure-state/qa/terraform.tfstate`
- Development: `infrastructure-state/dev/<branch-name>/terraform.tfstate`

## Outputs

The infrastructure deployment provides outputs that are consumed by the platform configuration:
- PingFederate admin and engine URLs
- API credentials
- Kubernetes namespace information
