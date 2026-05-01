output "logic_app_id" {
  description = "Resource ID of the Logic App workflow"
  value       = azurerm_logic_app_workflow.this.id
}

output "logic_app_name" {
  description = "Name of the Logic App workflow"
  value       = azurerm_logic_app_workflow.this.name
}

output "trigger_name" {
  description = "Name of the HTTP trigger — used to fetch the callback URL"
  value       = azurerm_logic_app_trigger_custom.http.name
}

output "callback_url_command" {
  description = "Run this to retrieve the SAS-signed callback URL (paste into Hookdeck). The URL is sensitive — anyone with it can invoke the workflow."
  value       = "az rest --method post --uri 'https://management.azure.com${azurerm_logic_app_workflow.this.id}/triggers/${azurerm_logic_app_trigger_custom.http.name}/listCallbackUrl?api-version=2016-06-01' --query value -o tsv"
}
