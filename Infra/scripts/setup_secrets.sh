#!/bin/bash
# setup_secrets_fixed.sh

set -e

echo "=== Azure Secrets Setup ==="

# Use your existing Key Vault that already works
KV_NAME="kv-quote-app-vault"  # CHANGE THIS if you want new name
RG_NAME="rg-tfstate-vault"
LOCATION="Central India"

echo "Using Key Vault: $KV_NAME"

echo -e "\n1. Checking if Key Vault exists..."
if ! az keyvault show --name "$KV_NAME" --resource-group "$RG_NAME" > /dev/null 2>&1; then
    echo "Creating Key Vault WITHOUT RBAC..."
    az keyvault create \
        --name "$KV_NAME" \
        --resource-group "$RG_NAME" \
        --location "$LOCATION" \
        --sku standard \
        --enable-rbac-authorization false
    echo "Key Vault created"
else
    echo "Key Vault already exists"
fi

echo -e "\n2. Storing passwords..."

# Generate passwords
CERT_PASS=123
#CERT_PASS=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9!@#$%&*()' | head -c 32)
SQL_PASS=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9!@#$%&*()' | head -c 32)

# Store passwords
az keyvault secret set \
    --vault-name "$KV_NAME" \
    --name "appgw-cert-password" \
    --value "$CERT_PASS"

az keyvault secret set \
    --vault-name "$KV_NAME" \
    --name "sql-admin-password" \
    --value "$SQL_PASS"

echo "Passwords stored"

echo -e "\n3. Uploading certificate..."

CERT_PATH="/root/cloudapp.pfx"
if [ -f "$CERT_PATH" ]; then
    # Upload as Base64
    CERT_BASE64=$(base64 -w0 "$CERT_PATH")
    az keyvault secret set \
        --vault-name "$KV_NAME" \
        --name "appgw-certificate-base64" \
        --value "$CERT_BASE64"
    echo "Certificate uploaded"
else
    echo "Certificate not found at: $CERT_PATH"
fi

echo -e "\n SETUP COMPLETE"
echo "Key Vault: $KV_NAME"
echo "Cert Password: $CERT_PASS"
echo "SQL Password: $SQL_PASS"
