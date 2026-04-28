output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "subnet_frontend_id" {
  value = azurerm_subnet.frontend.id
}

output "subnet_functions_id" {
  value = azurerm_subnet.functions.id
}

output "subnet_private_endpoints_id" {
  value = azurerm_subnet.private_endpoints.id
}

output "private_dns_zone_ids" {
  value = { for k, v in azurerm_private_dns_zone.zones : k => v.id }
}

output "private_dns_zone_names" {
  value = { for k, v in azurerm_private_dns_zone.zones : k => v.name }
}
