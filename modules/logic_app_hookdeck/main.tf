###############################################################################
# Hookdeck → Service Bus relay (Logic App, Consumption tier)
#
# A public HTTP trigger (auth via Logic Apps' built-in SAS signature in the
# callback URL — only Hookdeck has the URL) drops the body onto the
# `hookdeck_tview-queue` Service Bus queue. Mirrors the JSON definition the
# dev environment runs.
###############################################################################
data "azurerm_subscription" "current" {}

locals {
  managed_api_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/servicebus"
  api_connection_name = "servicebus-${var.environment}"
}

###############################################################################
# Managed API connection — Service Bus
#
# parameter_values is sensitive; ignore_changes prevents drift noise when the
# auth rule's connection string rotates. To force a refresh, taint the resource.
###############################################################################
resource "azurerm_api_connection" "servicebus" {
  name                = local.api_connection_name
  resource_group_name = var.resource_group_name
  managed_api_id      = local.managed_api_id
  display_name        = "Hookdeck → Service Bus"

  parameter_values = {
    connectionString = var.service_bus_connection_string
  }

  lifecycle {
    ignore_changes = [parameter_values]
  }
}

###############################################################################
# Logic App workflow
#
# `parameters.$connections` wires the workflow to our newly-minted API
# connection. `workflow_parameters.$connections` declares the parameter that
# the trigger/action JSON references via @parameters('$connections').
###############################################################################
resource "azurerm_logic_app_workflow" "this" {
  name                = "logic-${var.project}-hookdeck-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  parameters = {
    "$connections" = jsonencode({
      servicebus = {
        id             = local.managed_api_id
        connectionId   = azurerm_api_connection.servicebus.id
        connectionName = azurerm_api_connection.servicebus.name
      }
    })
  }

  workflow_parameters = {
    "$connections" = jsonencode({
      type         = "Object"
      defaultValue = {}
    })
  }
}

###############################################################################
# HTTP trigger (Request kind, concurrency-bounded)
###############################################################################
resource "azurerm_logic_app_trigger_custom" "http" {
  name         = "When_an_HTTP_request_is_received"
  logic_app_id = azurerm_logic_app_workflow.this.id

  body = jsonencode({
    type = "Request"
    kind = "Http"
    inputs = {
      schema = {
        type = "string"
      }
    }
    runtimeConfiguration = {
      concurrency = {
        runs = var.concurrency_runs
      }
    }
  })
}

###############################################################################
# Service Bus send action
#
# The "@{...}" inside path is Logic App Workflow Definition Language, not
# Terraform interpolation. Only ${var.target_queue_name} is replaced by TF.
###############################################################################
resource "azurerm_logic_app_action_custom" "send_message" {
  name         = "Send_message"
  logic_app_id = azurerm_logic_app_workflow.this.id

  body = jsonencode({
    runAfter = {}
    type     = "ApiConnection"
    inputs = {
      host = {
        connection = {
          name = "@parameters('$connections')['servicebus']['connectionId']"
        }
      }
      method = "post"
      body = {
        ContentData = "@base64(triggerBody())"
        ContentType = "application/json"
      }
      path = "/@{encodeURIComponent(encodeURIComponent('${var.target_queue_name}'))}/messages"
      queries = {
        systemProperties = "None"
      }
    }
  })

  depends_on = [azurerm_logic_app_trigger_custom.http]
}
