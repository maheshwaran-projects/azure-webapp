#!/bin/bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Prerequisites:
#   - Azure CLI
#   - GitHub CLI (gh)
#   - jq
#
# Usage:
#   ./oidc.sh <APP_NAME> <ORG|USER/REPO> <FICS_FILE>
#
# Example:
#   ./oidc.sh ghazoidc1 jongio/ghazoidctest ./fics.json
# -----------------------------------------------------------------------------

IS_CODESPACE=${CODESPACES:-"false"}
if [[ "$IS_CODESPACE" == "true" ]]; then
    echo "This script doesn't work in GitHub Codespaces."
    echo "See: https://github.com/Azure/azure-cli/issues/21025"
    exit 0
fi

APP_NAME="$1"
REPO="$2"
FICS_FILE="$3"

# -----------------------------------------------------------------------------
# Azure Login & Subscription
# -----------------------------------------------------------------------------

echo "Checking Azure CLI login status..."
if ! az ad signed-in-user show --query 'id' -o tsv &>/dev/null; then
    az login -o none
fi

ACCOUNT=$(az account show --query '[id,name]' -o tsv)
echo "Current subscription:"
echo "$ACCOUNT"

read -r -p "Do you want to use the above subscription? (Y/n) " response
response=${response:-Y}
case "$response" in
    [yY][eE][sS]|[yY]) ;;
    *)
        echo "Run: az account set -s <subscription-id> and re-run the script."
        exit 0
        ;;
esac

SUB_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "SUBSCRIPTION_ID: $SUB_ID"
echo "TENANT_ID:       $TENANT_ID"

# -----------------------------------------------------------------------------
# Azure AD Application
# -----------------------------------------------------------------------------

echo "Checking for existing Azure AD application..."
APP_ID=$(az ad app list --all \
    --query "[?displayName=='$APP_NAME'] | [0].appId" -o tsv)

if [[ -z "$APP_ID" ]]; then
    echo "Creating Azure AD application..."
    APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
    echo "Waiting for app propagation..."
    sleep 30
else
    echo "Existing Azure AD application found."
fi

echo "APP_ID: $APP_ID"

# -----------------------------------------------------------------------------
# Service Principal
# -----------------------------------------------------------------------------

echo "Checking for Service Principal..."
SP_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv 2>/dev/null || true)

if [[ -z "$SP_ID" ]]; then
    echo "Creating Service Principal..."
    SP_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)
    echo "Waiting for SP propagation..."
    sleep 30
else
    echo "Existing Service Principal found."
fi

echo "SP_ID: $SP_ID"

# -----------------------------------------------------------------------------
# Role Assignment (Subscription Scoped)
# -----------------------------------------------------------------------------

echo "Checking Contributor role assignment..."

ROLE_EXISTS=$(az role assignment list \
  --assignee-object-id "$SP_ID" \
  --scope "/subscriptions/$SUB_ID" \
  --query "[?roleDefinitionName=='Contributor'] | length(@)" \
  -o tsv)

if [[ "$ROLE_EXISTS" == "0" ]]; then
    echo "Creating Contributor role assignment at subscription scope..."
    az role assignment create \
      --assignee-object-id "$SP_ID" \
      --assignee-principal-type ServicePrincipal \
      --role Contributor \
      --scope "/subscriptions/$SUB_ID"
else
    echo "Contributor role assignment already exists."
fi

# -----------------------------------------------------------------------------
# Federated Identity Credentials (OIDC)
# -----------------------------------------------------------------------------

echo "Creating Federated Identity Credentials..."
echo

for FIC in $(envsubst < "$FICS_FILE" | jq -c '.[]'); do
    SUBJECT=$(jq -r '.subject' <<< "$FIC")
    echo "Creating FIC with subject: $SUBJECT"
    az ad app federated-credential create \
      --id "$APP_ID" \
      --parameters "$FIC" \
      || echo "FIC already exists, skipping."
done

# -----------------------------------------------------------------------------
# GitHub Secrets
# -----------------------------------------------------------------------------

echo
echo "GitHub secrets to be created:"
echo "  AZURE_CLIENT_ID        = $APP_ID"
echo "  AZURE_SUBSCRIPTION_ID  = $SUB_ID"
echo "  AZURE_TENANT_ID        = $TENANT_ID"
echo

echo "Logging into GitHub CLI..."
gh auth login

gh secret set AZURE_CLIENT_ID        -b"$APP_ID"  --repo "$REPO"
gh secret set AZURE_SUBSCRIPTION_ID  -b"$SUB_ID"  --repo "$REPO"
gh secret set AZURE_TENANT_ID        -b"$TENANT_ID" --repo "$REPO"

echo
echo "OIDC setup completed successfully!"

