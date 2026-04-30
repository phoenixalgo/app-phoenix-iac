terraform {
  required_version = "~> 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.30.0, < 5.0.0" # azurerm_function_app_flex_consumption was added in 4.30
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }

  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
}

locals {
  default_tags = {
    environment = var.environment
    project     = var.project
    managed-by  = "terraform"
    repository  = "phoenixapp_iac"
  }
}
