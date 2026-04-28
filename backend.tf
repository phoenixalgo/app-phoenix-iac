###############################################################################
# Remote state backend — Azure Storage with encryption
#
# Prerequisites: run bootstrap/create-state-storage.sh once before terraform init.
#
# The state key is NOT hardcoded — pass it at init time per environment:
#   terraform init -backend-config="key=phoenixapp.test.tfstate"
#   terraform init -backend-config="key=phoenixapp.staging.tfstate"
#   terraform init -backend-config="key=phoenixapp.prod.tfstate"
###############################################################################
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-phoenix-tfstate"
    storage_account_name = "stphoenixterraform"
    container_name       = "tfstate"
    use_azuread_auth     = true
  }
}
