# GitOps Lab Infrastructure

This repository contains the infrastructure components for the GitOps Lab platform, including Kubernetes deployments and Helm charts for PingFederate and PingDirectory.

## Components

- **Infrastructure**: Terraform configurations for Kubernetes infrastructure
- **Server Profiles**: Configuration profiles for Ping products
- **Helm Charts**: Kubernetes deployment configurations
- **Scripts**: Deployment and management scripts

## Quick Start

1. Configure your environment variables in `localsecrets`
2. Deploy infrastructure: `./scripts/deploy-infrastructure.sh`
3. Verify deployment: `kubectl get pods -n <namespace>`

## Dependencies

This infrastructure is designed to work with the [GitOps Lab Platform](https://github.com/your-org/gitops-lab-platform) repository for application configuration.

## Documentation

- [Infrastructure Deployment Guide](docs/infrastructure-deployment.md)
- [Kubernetes Configuration](docs/kubernetes-setup.md)
- [Troubleshooting](docs/troubleshooting.md)
