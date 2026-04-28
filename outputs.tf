###############################################################################
# Outputs — key information needed after terraform apply
###############################################################################

# Resource Group
output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

# Frontend
output "frontend_url" {
  value = module.frontend.app_url
}

output "frontend_app_name" {
  value = module.frontend.app_name
}

# Function App Hostnames (private — only reachable via VNet)
output "func_alpacadatamanager_hostname" {
  value = module.func_alpacadatamanager.default_hostname
}

output "func_portfoliomanager_hostname" {
  value = module.func_portfoliomanager.default_hostname
}

output "func_okxmanager_hostname" {
  value = module.func_okxmanager.default_hostname
}

output "func_hyperliquidmanager_hostname" {
  value = module.func_hyperliquidmanager.default_hostname
}

output "func_angelonemanager_hostname" {
  value = module.func_angelonemanager.default_hostname
}

# ACR
output "acr_login_server" {
  value = module.acr.login_server
}

# Key Vault
output "key_vault_name" {
  value = module.keyvault.vault_name
}

output "key_vault_uri" {
  value = module.keyvault.vault_uri
}

# Service Bus
output "servicebus_namespace" {
  value = module.servicebus.namespace_name
}

# Storage
output "data_storage_account" {
  value = module.storage.data_account_name
}

output "func_storage_account" {
  value = module.storage.func_runtime_account_name
}

###############################################################################
# Post-deploy instructions
###############################################################################
output "post_deploy_instructions" {
  value = <<-EOT

    ====================== POST-DEPLOY STEPS ======================

    1. Retrieve function host keys and update frontend app settings:
       az functionapp keys list \
         --name func-alpacadm-${var.environment} \
         --resource-group ${azurerm_resource_group.main.name}
       (repeat for portfoliomgr, angelonemgr)

    2. Update Key Vault placeholder secrets:
       ALPACA-API-KEY, ALPACA-API-SECRET, TELEGRAM-BOT-TOKEN,
       OKX-*, ANGELONE-* secrets

    3. Create Auth0 test application and update terraform.tfvars
       Callback URL: ${module.frontend.app_url}/api/auth/callback
       Logout URL:   ${module.frontend.app_url}

    4. Deploy function app code:
       func azure functionapp publish func-alpacadm-${var.environment}
       func azure functionapp publish func-portfoliomgr-${var.environment}
       func azure functionapp publish func-okxmgr-${var.environment}
       func azure functionapp publish func-hlmgr-${var.environment}
       func azure functionapp publish func-angelonemgr-${var.environment}

    5. Build & push frontend Docker image (uses Azure AD, no admin creds):
       az acr login --name ${module.acr.name}
       docker build -t ${module.acr.login_server}/manualtrades-fe:latest .
       docker push ${module.acr.login_server}/manualtrades-fe:latest
       az webapp restart --name ${module.frontend.app_name} \
         --resource-group ${azurerm_resource_group.main.name}

    ================================================================
  EOT
}
