###############################################################################
# Remote state backend — Azure Storage with encryption
#
# Prerequisites: run bootstrap/create-state-storage.sh once before terraform init.
# The bootstrap script creates the storage account with:
#   - Infrastructure encryption (double encryption at rest)
#   - Blob versioning (state history / rollback)
#   - CanNotDelete lock (prevents accidental removal)
#   - TLS 1.2 minimum
###############################################################################
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-phoenix-tfstate"
    storage_account_name = "stphoenixterraform"
    container_name       = "tfstate"
    key                  = "phoenixapp.test.tfstate"
    use_azuread_auth     = true # Uses Azure AD instead of storage account keys
  }
}
