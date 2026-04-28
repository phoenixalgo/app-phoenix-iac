output "namespace_id" {
  value = azurerm_servicebus_namespace.main.id
}

output "namespace_name" {
  value = azurerm_servicebus_namespace.main.name
}

output "connection_string" {
  value     = azurerm_servicebus_namespace_authorization_rule.app_policy.primary_connection_string
  sensitive = true
}

output "namespace_endpoint" {
  value = azurerm_servicebus_namespace.main.endpoint
}
