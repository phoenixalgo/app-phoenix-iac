output "connection_string" {
  description = "Application Insights connection string. Empty when monitoring is disabled."
  value       = var.enabled ? azurerm_application_insights.this[0].connection_string : ""
  sensitive   = true
}

output "instrumentation_key" {
  description = "Application Insights instrumentation key. Empty when monitoring is disabled."
  value       = var.enabled ? azurerm_application_insights.this[0].instrumentation_key : ""
  sensitive   = true
}

output "workspace_id" {
  description = "Log Analytics workspace resource ID. Empty when monitoring is disabled."
  value       = var.enabled ? azurerm_log_analytics_workspace.this[0].id : ""
}

output "app_insights_id" {
  description = "Application Insights resource ID. Empty when monitoring is disabled."
  value       = var.enabled ? azurerm_application_insights.this[0].id : ""
}
