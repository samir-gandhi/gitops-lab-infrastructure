#!/usr/bin/env sh

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Export the token for use in the kubeconfig template
KUBE_TOKEN="$(kubectl create token ping-devops-admin)"
export KUBE_TOKEN

# Use absolute paths for all files
envsubst < "${SCRIPT_DIR}/@kubeconfig.subst" > "${SCRIPT_DIR}/@kubeconfig"
base64 -i "${SCRIPT_DIR}/@kubeconfig" | tr -cd "[:print:]" > "${SCRIPT_DIR}/@kubeconfigb64"
gh secret set KUBECONFIG_YAML < "${SCRIPT_DIR}/@kubeconfigb64"