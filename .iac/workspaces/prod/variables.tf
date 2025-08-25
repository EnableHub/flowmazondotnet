
# vars for "registry" module to create container registry
variable "acr_resource_group_name" {
  description = "Name of the resource group that would be created. The Azure Container Registry instance created by this module would be placed in this resource group."
  type        = string

}

variable "acr_resource_group_location" {
  description = "Location of the resource group that would be created. Pick a location from the Region column in this table: https://learn.microsoft.com/en-us/azure/reliability/regions-list#azure-regions-list-1"
  type        = string
}

variable "acr_name" {
  description = "Name of the Azure Container Registry instance that would be created."
  type        = string
}

# Variables for id_vault module
#
# The module also uses some variables decalred for other
# modules above.

variable "key_vault_name" {
  description = "The name of the key vault that would be created."
  type        = string
}

variable "managed_identity_name" {
  description = "The name of the user-assigned managed identity that would be created."
  type        = string
}

variable "id_and_vault_resource_group_name" {
  description = "The name of the resource group that would be created. The user-assigned managed identity and the key vault creaetd by this module would be placed in this resource group."
  type        = string
}

variable "id_and_vault_resource_group_location" {
  description = "The location of the resource group that would be created. Pick a location from the Region column in this table: https://learn.microsoft.com/en-us/azure/reliability/regions-list#azure-regions-list-1"
  type        = string
}

# variables relating to storing secrets and/or variables
# in GitHub repo's Environment; used by db and flowmazonfrontend 
# modules
variable "secretname_for_psql_owner_connectionstring" {
  description = "Name of the GitHub Environment secret in which to store psql connection String that includes credentials of db owner account that would be used to connect to and execute queries (including DDL) on the database from psql. This should be set to 'TF_MANAGED_PSQL_OWNER_CONNECTIONSTRING` as this is the name used by GitHub Actions workflows that read the value of this secret - i.e. the connection string - which they would use to run migrations against the database."
  type        = string
}

variable "secretname_for_neon_project_default_branch_id" {
  description = "Name of the secret in GitHub Environment in which to store default branch id of the Neon DB project that would be created. This should have the value 'TF_MANAGED_NEON_SOURCE_BRANCH_ID' as this is the name that would be used by GitHub Actions workflows that read the value of this secret."
  type        = string
}

variable "secretname_for_neon_project_id" {
  description = "Name of the secret in GitHub Environment in which to store project id of the Neon DB project that would be created. The value of this variable should be 'TF_MANAGED_NEON_PROJECT_ID' as this is the name that would be used by GitHub Actions workflows that read the value of this secret."
  type        = string
}

variable "secretname_for_vercel_project_id" {
  description = "Name of the GitHub Environment secret in which to store project_id of the created vercel_project. This should have the value 'TF_MANAGED_VERCEL_PROJECT_ID' as this is the name that would be used by GitHub Actions workflows that read the value of this secret."
  type        = string
}

variable "environmentname_for_secrets_and_variables" {
  description = "Name of GitHub repo Environment in which to store secrets and variables such as vercel_project_id and psql_owner_connection_string."
  type        = string
}

variable "repository_for_secrets_and_variables" {
  description = "Name of GitHub repo in an an Environment of which (specified by `environmentname_for_secrets_and_variables` argument) secrets and variables such as vercel_project_id and psql_owner_connection_string would be stored. This should just be the repo's name, and NOT prefixed by account name or organisation name and NOT a fully qualified repo name either. Otherwise the repo may not be found. For example I would provide `flowmazondotnet` as the repo name instead of `EnableHub/flowmazondotnet` or `https://github.com/EnableHub/flowmazondotnet`."
  type        = string
}


# variables for db module

# We already have values for the following vars for this module:

# vault_resource_group_name
# vault_name
# managed_identity_for_secret
# managed_identity_for_secret_resource_group_name


variable "vault_secretname_for_connectionstring" {
  description = "Name of the Azure Key Vault secret into which the application connection string. This should be set to the same value as that is provided to 'prod-api' TF workspace as a value of a variable with the same name. prod-api workspace creates the Azure Container App in which the API app would read it, then fetch its value from the Azure Key Vault; it would then use the retrieved value - the connection string - to connect to the database."
  type        = string
}

# Neon DB variables for db module
# This can be found on Settings page in the Neon DB UI
variable "neon_org_id" {
  description = "Organization ID of the Neon Organization in which the new project would be created."
  type        = string
  sensitive   = true
}


variable "neon_project_name" {
  description = "The name for the Neon project that would be created."
  type        = string
}

variable "neon_branch_name" {
  description = "The name for the default Neon branch for the project (e.g., 'main' or 'prod')."
  type        = string
}

variable "neon_database_name" {
  description = "The name of the database to be created in Neon (e.g., 'flowmazondb')."
  type        = string
}

# for the following role names,
# bear in mind that in NeonDB roles and users
# are synonymous
variable "neon_app_role" {
  description = "The name for the Neon database role that would be created; it would be used by the API app to connect to the database."
  type        = string
  sensitive   = true

}

variable "neon_owner_role" {
  description = "The name for the Neon database owner role that would be created; it would be used by the continuous delivery pipeline to migrate the database."
  type        = string
  sensitive   = true

}



# vars needed for Vercel provider used by flowmazonfrontend module
variable "cloudflare_api_token" {
  description = "CloudFlare's API Token."
  type        = string
  sensitive   = true

}

variable "cloudflare_zone_id" {
  description = "Zone ID of the apex domain for domain name specified in api_domain_name variable."
  type        = string
  sensitive   = true
}

# vars needed by cloudflare_rate_limiting_rule module
variable "rate_limit_requests_per_period" {
  description = "number of request that, if received in the configured `period` (fixed to 10 seconds in free plan), would lead to the sending IP being blocked for the configured `mitigation_timeout` (also fixed to 10 seconds in free plan)"
  type        = number
}

variable "cloudflare_rate_limiting_rule_name" {
  description = "Name of the rate limiting rule. This has several nuances, including why it is created at the Zone level rather than hostname level and why it defaults to value \"default\". See README of Terraform module `cloudflare_rate_limiting_rule` for details on the value of this variable and how to ensure that any existing rate limiting rule is deleted."
  type        = string
  default     = "default"

}

# vars for flowmazonfrontend module
#
# We already have (above) the remaining variabls requried by
# the flowmazonfrontend module:
#
# cloudflare_api_token
# cloudflare_zone_id

variable "vercel_team_id" {
  description = "Team ID displayed on the Settings page of a Team in your Vercel account. We need this to create a project, and the project would be created in in the team with the given Team ID. Bear in mind that in a free Vercel account, you only have the default team and cannot create a new one without upgrading."
  type        = string
  sensitive   = true
}

variable "vercel_project_name" {
  description = "Name of the Vercel project that would be created."
  type        = string
  sensitive   = true

}

variable "vercel_app_domain_name" {
  description = "Desired domain name for the Vercel project. This will be mapped to the project's own (Vercel generated) domain name in vercel through a CNAME record in an external DNS provider like Cloudflare."
  type        = string
}

variable "vercel_region_for_server_side_execution" {
  description = "see flowmazonfrontend module's documentation"
  type        = string
}

variable "env_NEXT_PUBLIC_OTEL_ENVIRONMENT" {
  description = "Name of the Otel environment. This would be reported as value of semantic convention 'deployment.environment.name' to the observability backend. This variable would be set as an environment variable on the created Vercel app. See project wiki for the value of this variable in a particular environment."
  type        = string
}

variable "env_OTEL_EXPORTER_OTLP_ENDPOINT" {
  description = "OTLP endpoint of the observability backend. This variable would be set as an environment variable on the created Vercel app."
  type        = string
}

variable "env_OTEL_EXPORTER_OTLP_PROTOCOL" {
  description = "The transport, e.g. grpc or http/protobuf, that would be used to write telemetry to the OTLP endpoint. This variable would be set as an environment variable on the created Vercel app."
  type        = string
}

variable "env_OTEL_EXPORTER_OTLP_HEADERS" {
  description = "Authorization header that would be provided when writing telemetry to the observability backend using OpenTelemetry protocol. Grafana Cloud would show this if you press Details button on your Stack, then generate a new token; base-64 encoded value of this token would be included in the generated Authorization header that would be shown. This variable would be set as an environment variable on the created Vercel app and marked as SENSITIVE."
  type        = string
  sensitive   = true
}

variable "grafanacloud_frontend_o11y_api_access_token" {
  description = "Access token for Grafana Cloud Frontend Observability API. This is used to create a new Frontend Observability instance in the Grafana Cloud stack. Obtain it as described here: https://registry.terraform.io/providers/grafana/grafana/latest/docs#managing-frontend-observability. I Would also use it as cloud_access_policy_token in the grafana provider block. Therefore it should additionally also have the following scopes: accesspolicies:read|write|delete, stacks:read|write|delete."
  type        = string
  sensitive   = true

}

variable "grafanacloud_stack_slug" {
  description = "The slug of the Grafana Cloud stack in which to create a new Frontend Observability instance. This is the subdomain of the Grafana Cloud stack URL that is shown on the Stack page in Grafana Cloud. For example, if the URL is https://my-stack.grafana.net, then the slug is 'my-stack'."
  type        = string
}

variable "grafanacloud_frontend_o11y_instance_name" {
  description = "Name of the Frontend Observability instance that would be created in the Grafana Cloud stack."
  type        = string
}

variable "secretname_for_grafanacloud_frontend_o11y_instance_url" {
  description = "Name of the GitHub Environment secret in which to store the URL of the created Grafana Cloud Frontend Observability instance. This is used by GitHub Actions workflows."
  type        = string
}

variable "secretname_for_neon_owner_role_password" {
  description = "Name of the GitHub Environment secret in which to store password of db owner Neon role (whose name is passed into input variable `neon_owner_role` in this module). This can be used to construct psql connection strings (for running migrations etc.) for Neon project branches created by any Terraform configuration that runs later."
  type        = string
}

variable "secretname_for_neon_app_role_password" {
  description = "Name of the GitHub Environment secret in which to store password of Neon role for app user (whose name is passed into input variable `neon_app_role` in this module). This can be used to construct connection strings to be used by client apps for Neon project branches created by any Terraform configuration that runs later."
  type        = string
}
