# Default tfvars — use environment-specific files instead:
#   terraform plan -var-file=environments/test.tfvars
#   terraform plan -var-file=environments/staging.tfvars
#
# This file is kept as a fallback for `terraform plan` without -var-file.
subscription_id = "36f01b52-3a98-440f-af52-257de940d26c"
environment     = "test"
location        = "australiaeast"
project         = "phoenix"

function_app_plan_sku = "P1v2"
frontend_app_plan_sku = "B1"
