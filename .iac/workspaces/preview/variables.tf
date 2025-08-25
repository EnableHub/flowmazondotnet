
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
  description = "The location of the resource group that would be created."
  type        = string
}

# variables for db module

# We already have values for the followin vars for this module:

# vault_resource_group_name
# vault_name
# managed_identity_for_secret
# managed_identity_for_secret_resource_group_name

variable "vault_secretname_for_connectionstring" {
  description = "name of the secret whose value is the connection string to be used by the API to connect to the database. For this workspace it doesn't matter what this name is as this connection string will not be used by any of the ephemeral Preview environments - create via preview-ephemeral-XXX Terraform workspaces - that will share the database created by this workspace."
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
  description = "The name for the Neon database role that the application will use."
  type        = string
  sensitive   = true

}

variable "neon_owner_role" {
  description = "The name for the Neon database owner role."
  type        = string
  sensitive   = true

}

variable "secretname_for_psql_owner_connectionstring" {
  description = "Name of the GitHub Environment secret in which to store psql connection String that includes credentials of db owner account that would be used to connect to and execute queries (including DDL) on the database from psql."
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

variable "secretname_for_neon_project_default_branch_id" {
  description = "Name of the secret in GitHub Environment in which to store default branch id of the Neon DB project that would be created."
  type        = string
}

variable "secretname_for_neon_project_id" {
  description = "Name of the secret in GitHub Environment in which to store project id of the Neon DB project that would be created."
  type        = string
}

variable "environmentname_for_secrets_and_variables" {
  description = "Name of GitHub repo Environment in which to store secrets or variables."
  type        = string
}

variable "repository_for_secrets_and_variables" {
  description = "Name of GitHub repo in an an Environment of which (specified by `environmentname_for_secrets_and_variables` argument) secretes or variables would be stored by this workspace. This should just be the repo's name, and NOT prefixed by account name or organisation name and NOT a fully qualified repo name either. Otherwise the repo may not be found. For example I would provide `flowmazondotnet` as the repo name instead of `EnableHub/flowmazondotnet` or `https://github.com/EnableHub/flowmazondotnet`."
  type        = string
}

# vars needed for vercel provider used by flowmazonfrontend module
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
  description = "Name of the rate limiting rule. This has several nuances, including why it is created at the Zone level rather than hostname level and why it defaults to value \"default\". See README of module cloudflare_rate_limiting_rule for details."
  type        = string
  default     = "default"

}
