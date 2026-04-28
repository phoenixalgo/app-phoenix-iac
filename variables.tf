###############################################################################
# General
###############################################################################
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. test, staging, prod)"
  type        = string
  default     = "test"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "australiaeast"
}

variable "project" {
  description = "Project name used in resource naming"
  type        = string
  default     = "phoenix"
}

###############################################################################
# Networking
###############################################################################
variable "vnet_address_space" {
  description = "VNet address space"
  type        = string
  default     = "10.0.0.0/16"
}

###############################################################################
# Compute SKUs
###############################################################################
variable "function_app_plan_sku" {
  description = "App Service Plan SKU for Function Apps (needs P1v2+ for private endpoints)"
  type        = string
  default     = "P1v2"
}

variable "frontend_app_plan_sku" {
  description = "App Service Plan SKU for the frontend (B1 is fine — publicly accessible)"
  type        = string
  default     = "B1"
}

###############################################################################
# Auth0 (set via tfvars or env — never commit secrets)
###############################################################################
variable "auth0_domain" {
  description = "Auth0 domain (e.g. myapp.au.auth0.com)"
  type        = string
  default     = ""
}

variable "auth0_client_id" {
  description = "Auth0 application client ID for the test environment"
  type        = string
  default     = ""
}

variable "auth0_client_secret" {
  description = "Auth0 application client secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "auth0_secret" {
  description = "Random string used to encrypt Auth0 session cookies"
  type        = string
  sensitive   = true
  default     = ""
}
