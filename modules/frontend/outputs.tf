output "app_url" {
  value = "https://${azurerm_linux_web_app.frontend.default_hostname}"
}

output "app_name" {
  value = azurerm_linux_web_app.frontend.name
}

output "default_hostname" {
  value = azurerm_linux_web_app.frontend.default_hostname
}
