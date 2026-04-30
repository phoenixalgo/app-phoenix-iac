###############################################################################
# Monitoring — Log Analytics Workspace + Application Insights
#
# A single workspace + AI component is shared across all function apps. Each
# function app's logs are auto-tagged with cloud_RoleName = <function app name>,
# so per-app filtering in KQL is trivial.
#
# Both resources are gated by `var.enabled` — flipping the toggle off removes
# them entirely (and removes the AI connection string from each function app).
###############################################################################
resource "azurerm_log_analytics_workspace" "this" {
  count               = var.enabled ? 1 : 0
  name                = "law-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days
}

resource "azurerm_application_insights" "this" {
  count               = var.enabled ? 1 : 0
  name                = "appi-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this[0].id
  application_type    = "web"
}
