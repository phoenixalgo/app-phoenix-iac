subscription_id = "36f01b52-3a98-440f-af52-257de940d26c"
environment     = "test"
location        = "australiaeast"
project         = "phoenix"

function_app_plan_sku = "FC1"
frontend_app_plan_sku = "B1"

# Observability — flip to false to remove App Insights + LAW entirely
enable_application_insights = false

# Auth0 (non-secret values — secrets live in Key Vault, populated manually)
auth0_domain    = "dev-1hmmvopl55l2lnoc.us.auth0.com"
auth0_client_id = "m5zBIIcHqbujxXQhBfwXE9SzEbGG7hWU"
