#!/bin/bash
# setup_secrets_rbac.sh

set -e

echo "=== Azure Secrets Setup (RBAC Mode) ==="

KV_NAME="kv-quote-app-vault1"
RG_NAME="rg-tfstate-vault"
LOCATION="centralindia"

echo "Using Key Vault: $KV_NAME"

# Get current logged-in principal (user / service principal / managed identity)
CURRENT_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)

if [ -z "$CURRENT_OBJECT_ID" ]; then
  echo "Signed-in user not found, trying service principal..."
  CURRENT_OBJECT_ID=$(az account show --query user.name -o tsv)
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo -e "\n1. Checking if Key Vault exists..."
if ! az keyvault show --name "$KV_NAME" --resource-group "$RG_NAME" > /dev/null 2>&1; then
    echo "Creating Key Vault WITH RBAC enabled..."
    az keyvault create \
        --name "$KV_NAME" \
        --resource-group "$RG_NAME" \
        --location "$LOCATION" \
        --sku standard \
        --enable-rbac-authorization true
    echo "Key Vault created"
else
    echo "Key Vault already exists"
fi

echo -e "\n2. Assigning RBAC role (Key Vault Secrets Officer)..."

az role assignment create \
  --assignee-object-id "$CURRENT_OBJECT_ID" \
  --assignee-principal-type User \
  --role "Key Vault Secrets Officer" \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.KeyVault/vaults/$KV_NAME \
  --only-show-errors || echo "Role assignment may already exist"

echo "RBAC role assigned"

# Small wait for RBAC propagation (important in real life & assessments)
echo "Waiting for RBAC propagation..."
sleep 15

echo -e "\n3. Storing passwords..."

CERT_PASS=123
SQL_PASS=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9!@#$%&*()' | head -c 32)

az keyvault secret set \
    --vault-name "$KV_NAME" \
    --name "appgw-cert-password" \
    --value "$CERT_PASS"

az keyvault secret set \
    --vault-name "$KV_NAME" \
    --name "sql-admin-password" \
    --value "$SQL_PASS"

echo "Passwords stored"

echo -e "\n4. Uploading certificate..."

CERT_PATH="/root/cloudapp.pfx"
if [ -f "$CERT_PATH" ]; then
    CERT_BASE64=$(base64 -w0 "$CERT_PATH")
    az keyvault secret set \
        --vault-name "$KV_NAME" \
        --name "appgw-certificate-base64" \
        --value "$CERT_BASE64"
    echo "Certificate uploaded"
else
    echo "Certificate not found at: $CERT_PATH"
fi

echo -e "\n=== SETUP COMPLETE ==="
echo "Key Vault: $KV_NAME"
echo "Cert Password: $CERT_PASS"
echo "SQL Password: $SQL_PASS"

