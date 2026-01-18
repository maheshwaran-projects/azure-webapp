#!/bin/bash
set -e

# ================================
# VARIABLES
# ================================
SUBSCRIPTION_ID="74c4f319-b9f6-4b4f-b910-b6bb2923cf97"
LOCATION="centralindia"

TFSTATE_RG="rg-tfstate-vault"
STORAGE_ACCOUNT_NAME="tfstatequote525"
CONTAINER_NAME="tfstate"

SP_NAME="terraform-backend-sp"

# ================================
# LOGIN
# ================================
az account show >/dev/null 2>&1 || az login
az account set --subscription "$SUBSCRIPTION_ID"

# ================================
# RESOURCE GROUP
# ================================
az group create \
  --name "$TFSTATE_RG" \
  --location "$LOCATION"

# ================================
# STORAGE ACCOUNT
# ================================
az storage account create \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$TFSTATE_RG" \
  --location "$LOCATION" \
  --sku Standard_ZRS \
  --kind StorageV2 \
  --https-only true \
  --allow-blob-public-access false

# ================================
# CONTAINER
# ================================
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --auth-mode login \
  --public-access off


