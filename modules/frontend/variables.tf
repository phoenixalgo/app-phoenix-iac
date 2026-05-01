variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "environment" { type = string }
variable "project" { type = string }
variable "app_plan_sku" { type = string }

variable "subnet_frontend_id" {
  description = "Subnet for VNet integration (outbound to private endpoints)"
  type        = string
}

variable "acr_login_server" { type = string }
variable "acr_id" { type = string }

# Backend URLs
variable "api_base_url" { type = string }
variable "marketregime_api_base_url" { type = string }
variable "angelone_api_base_url" { type = string }

# Key Vault (all secrets resolved via @Microsoft.KeyVault references)
variable "key_vault_id" { type = string }
variable "key_vault_uri" { type = string }

# Auth0 (non-secret values passed directly)
variable "auth0_domain" { type = string }
variable "auth0_client_id" { type = string }

variable "home_ip_cidr" {
  description = "Optional CIDR allowed to reach the frontend public hostname. When set, every other source is denied. Empty leaves the FE open to the internet (Auth0 is then the only gate)."
  type        = string
  default     = ""
}
