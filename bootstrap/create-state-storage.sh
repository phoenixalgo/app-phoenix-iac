#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# Bootstrap: create the storage account for Terraform remote state.
# Run this ONCE before `terraform init`.
# ──────────────────────────────────────────────────────────────────
set -euo pipefail

RG_NAME="rg-phoenix-tfstate"
SA_NAME="stphoenixterraform"
CONTAINER="tfstate"
LOCATION="australiaeast"

echo "Creating resource group ${RG_NAME}..."
az group create --name "$RG_NAME" --location "$LOCATION" --output none

echo "Creating storage account ${SA_NAME} with infrastructure encryption..."
az storage account create \
  --name "$SA_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --require-infrastructure-encryption true \
  --output none

echo "Creating blob container ${CONTAINER}..."
az storage container create \
  --name "$CONTAINER" \
  --account-name "$SA_NAME" \
  --auth-mode login \
  --output none

echo "Enabling blob versioning for state history..."
az storage account blob-service-properties update \
  --account-name "$SA_NAME" \
  --resource-group "$RG_NAME" \
  --enable-versioning true \
  --output none

echo "Enabling storage account delete lock..."
az lock create \
  --name "protect-tfstate" \
  --resource-group "$RG_NAME" \
  --resource "$SA_NAME" \
  --resource-type "Microsoft.Storage/storageAccounts" \
  --lock-type CanNotDelete \
  --notes "Protects Terraform state storage from accidental deletion" \
  --output none

echo ""
echo "Bootstrap complete. Now run:"
echo "  cd C:\\Users\\rohit\\phoenixapp_iac"
echo "  terraform init"
