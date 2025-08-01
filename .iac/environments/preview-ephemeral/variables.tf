# Cloudflare variables used by both modules
############################################################
# To generate this token, create an Account API token by going
# to your user profile in your CloudFalre account, then clicking
# **API Token** in the nav on the left hand side.
#
# Note an Account API token is preferred to a User API token.
#
# Give the token the following permissions: 
# 1. 'Zone | DNS | Edit` (to create and modify TXT and CNAME records)
# 2. 'Zone | Zone WAF | Edit` (to set rate limiting rule)
# to 'on' which ensures that CloudFlare would present a certificate
# to target of CNAME record when communicating with it; this 
# achieves mTLS.
# 
# Make sure that the zone of interest on which these permissions apply
# is also selected under 'Zone Resources' - or 'All zones from the acount' 
# is selected - when you assign permissions to the token.
#
variable "cloudflare_api_token" {
  description = "CloudFlare's API Token."
  type        = string
  sensitive   = true
}

# TODO: document this in my environments documentation
#
# I assume you already have a DNS zone with CloudFlare for
# the apex domain used in the domain name of the app. For example
# if the domain name if `api.efast.uk`, the apex domain is
# efast.uk.
#
# Create this zone by transferring setting Cloudflare's nameservers
# as nameservers of the apex domain in control panel of the registrar
# from whom you purchased the apex domain.
# Cloudflare would also guide you through the process.

# Once you have created an zone, i.e. Cloudflare manage
# DNS queries for the apex domain, then go to CloudFlare Dashboard.
# There click the apex domain name, and you would be taken to
# the detail page of the associated zone. ZoneID would be 
# displayed on this page (you may have to scroll down the page).
variable "cloudflare_zone_id" {
  description = "Zone ID of the apex domain for domain name specified in api_domain_name variable."
  type        = string
  sensitive   = true
}

# vars for aca_app module

variable "app_resource_group_name" {
  description = "The name of the Azure resource group in which the app would be created."
  type        = string
}

variable "app_resource_group_location" {
  description = "Location of the Azure resource group n which the app would be created."
  type        = string
}

variable "app_name" {
  description = "Name of the ACA app that would be created."
  type        = string
}

variable "app_environment_name" {
  description = "Name of the ACA environment that would be created and would contain the ACA app"
  type        = string
}

variable "app_domain_name" {
  description = "The custom domain name for the app, e.g. api.efast.uk"
  type        = string
}

variable "app_container_name" {
  description = "Name of the Docker container that would be created in the ACA app"
  type        = string
}

variable "app_container_port" {
  description = "port at which the app container listens"
  type        = number
}

variable "github_organisation_or_account" {
  description = "Name o the GtHub repository's organisation or personal account. This will be used to construct the name of the orgnaisation ot account's Container registry - as `ghcr.io/<org or account name>` - from which container image for API would be pulled for the Preview environment (in this enviornment, in order to economise, the ACA app will not pull from an ACR instance as that costs whereas GitHub Pacakges is free)."

  type = string
}

variable "image_repository" {
  description = "Name of the Docker image to deploy (excluding the '<registry name>.azurecr.io/' prefix and the ':<tag>' suffix)"
  type        = string
}

variable "image_tag" {
  description = "tag of the image whose name is provided in `image_repository`"
  type        = string
}

variable "managed_identity_name" {
  description = "Name of the user-assigned managed identity that would be assigned to the ACA app. This would be used to pull image from Azure Container Regitry and read secret value from Azure Key Vault"
  type        = string
}

variable "id_and_vault_resource_group_name" {
  description = "Name of the Azure resource group in which the vault and user-assinged managed identity exists."
  type        = string
}

variable "key_vault_name" {
  description = "The name of the key vault from which secrets required by the app will be read."
  type        = string
}

# Variables for configuration specific to application logic
############################################################

# TODO: Make passing of secrets and non-secret
# config keys and values to the deployed app generic
# This would make the module reusable and publishable.
variable "vault_secretname_for_connectionstring" {
  description = "name of the secret whose value is the connection string to be used by the API to connect to the database"
  type        = string
}

variable "allowed_cors_origins_for_api" {
  description = "the string that would be set as value of config key ALLOWED_CORS_ORIGINS for the API"
  type        = string

}

locals {
  allowed_cors_origins_env_var_name = "ALLOWED_CORS_ORIGINS"
  connection_string_env_var_name    = "ConnectionStrings__FlowmazonDB"

}


# Otel Endpoint details
variable "env_OTEL_RESOURCE_ATTRIBUTES" {
  description = "Used to pass value of environment variable OTEL_RESOURCE_ATTRIBUTES that the API expects. See README of flowmazonbackend for details."
  type        = string
}

variable "env_OTEL_EXPORTER_OTLP_ENDPOINT" {
  description = "OTLP endpoint of the observability backend. This would be configured as a destination endpoint in ACAP app environment's Otel collector."
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

# vars for flowmazonfrontend module
#
# We already have (above) the remaining variables requried by
# the flowmazonfrontend module:
#
# cloudflare_api_token
# cloudflare_zone_id

variable "vercel_team_id" {
  description = "Team ID displayed on you Setting page of a Team in your Vercel account. We need this to create a project, and the project would be created in in the team with the given Team ID."
  type        = string
  sensitive   = true
}

variable "vercel_project_name" {
  description = "Name of the project that would be created."
  type        = string
  sensitive   = true

}

variable "vercel_app_domain_name" {
  description = "Desired domain name for the Vercel project. This will be mapped to the project's own domain name in vercel through a CNAME record with external DNS provider like Cloudflare."
  type        = string
}

variable "vercel_region_for_server_side_execution" {
  description = "see flowmazonfrontend module's documentation"
  type        = string
}

variable "env_NEXT_PUBLIC_OTEL_ENVIRONMENT" {
  description = "Name of the Otel environment. This would be reported as value of semantic convention 'deployment.environment.name' to the observability backend. This variable would be set as an environment variable on the created Vercel app."
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
