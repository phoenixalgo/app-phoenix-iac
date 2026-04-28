###############################################################################
# Azure Container Registry — Basic SKU, public access (per budget decision)
# Admin user disabled — pull access via managed identity + AcrPull RBAC role.
###############################################################################
resource "azurerm_container_registry" "main" {
  name                = "acr${var.project}${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
}
