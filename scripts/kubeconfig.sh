#!/usr/bin/env sh

# Strict mode: abort on error and undefined vars
set -eu

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Require necessary commands
for cmd in kubectl envsubst base64 tr gh; do
	command -v "$cmd" >/dev/null 2>&1 || {
		echo "Error: Required command '$cmd' not found in PATH" >&2
		exit 1
	}
done

# Ensure template exists
TEMPLATE_FILE="${SCRIPT_DIR}/@kubeconfig.subst"
[ -f "$TEMPLATE_FILE" ] || {
	echo "Error: Template file not found: $TEMPLATE_FILE" >&2
	exit 1
}

# Export the token for use in the kubeconfig template
if ! KUBE_TOKEN="$(kubectl create token ping-devops-admin)"; then
	echo "Error: Failed to create Kubernetes token with kubectl" >&2
	exit 1
fi
[ -n "$KUBE_TOKEN" ] || {
	echo "Error: Received empty Kubernetes token" >&2
	exit 1
}
export KUBE_TOKEN

# Secure file permissions for generated secrets
umask 077

# Render kubeconfig from template
OUT_YAML="${SCRIPT_DIR}/@kubeconfig"
if ! envsubst < "$TEMPLATE_FILE" > "$OUT_YAML"; then
	echo "Error: Failed to render kubeconfig via envsubst" >&2
	exit 1
fi
[ -s "$OUT_YAML" ] || {
	echo "Error: Rendered kubeconfig is empty: $OUT_YAML" >&2
	exit 1
}

# Base64 encode safely without masking errors in a pipeline
TMP_B64="$(mktemp "${SCRIPT_DIR}/.kubeconfigb64.XXXXXX")"
cleanup() { rm -f "$TMP_B64"; }
trap cleanup EXIT HUP INT TERM

if ! base64 -i "$OUT_YAML" > "$TMP_B64"; then
	echo "Error: base64 encoding failed" >&2
	exit 1
fi

OUT_B64="${SCRIPT_DIR}/@kubeconfigb64"
if ! tr -cd "[:print:]" < "$TMP_B64" > "$OUT_B64"; then
	echo "Error: Cleaning base64 output failed" >&2
	exit 1
fi
[ -s "$OUT_B64" ] || {
	echo "Error: Base64 output is empty: $OUT_B64" >&2
	exit 1
}

# Create or update GitHub secret
if ! gh secret set KUBECONFIG_YAML < "$OUT_B64"; then
	echo "Error: Failed to set GitHub secret KUBECONFIG_YAML" >&2
	exit 1
fi