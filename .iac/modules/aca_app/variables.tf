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

# Note we do not configure OTEL_EXPORTER_OTLP_PROTOCOL
# because teh app writes to teh ACA app environment's
# OTel collector which only supports gRPC
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

variable "vault_secretname_env_OTEL_EXPORTER_OTLP_HEADERS" {
  description = "The name of the key vault secret into which the value of the env_OTEL_EXPORTER_OTLP_HEADERS variable would be stored."
  type        = string
}

variable "env_OTEL_RESOURCE_ATTRIBUTES" {
  description = "Used to pass value of environment variable OTEL_RESOURCE_ATTRIBUTES that the API expects. See README of flowmazonbackend for details."
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

variable "app_container_liveness_probe" {
  description = "The pathname (starting with `/`) of the Liveness probe for the container (e.g. an endpoint `/health/live` implemented by the app running in the container). For more details see https://learn.microsoft.com/en-us/azure/container-apps/health-probes?tabs=arm-template"
  type        = string
  nullable    = true
}

variable "app_container_readiness_probe" {
  description = "The pathname (starting with `/`) of the Readiness probe for the container (e.g. an endpoint `/health/ready` implemented by the app running in the container). For more details see https://learn.microsoft.com/en-us/azure/container-apps/health-probes?tabs=arm-template"
  type        = string
  nullable    = true
}

variable "app_container_startup_probe" {
  description = "The pathname (starting with `/`) of the Startup probe for the container (e.g. an endpoint `/health/startup` implemented by the app running in the container). For more details see https://learn.microsoft.com/en-us/azure/container-apps/health-probes?tabs=arm-template"
  type        = string
  nullable    = true
}

variable "app_container_max_replicas" {
  description = "Mazimum number of replicas that the container should scale to."
  type        = number
  default     = 1 # safe, and economical for toy apps
}

variable "acr_name" {
  description = "The name of the Azure Ccontainer Registry instance which contains the image to be deployed to the ACA app. IF you provide a non-null value for this argument then a non-null value should also be provided for `acr_resource_group_name` argumetn AND a value should NOT be provided for `image_server` argument."
  type        = string
  default     = null
}

variable "acr_resource_group_name" {
  description = "Name of the Azure resource group in which the ACR instance exists. IF you provide a non-null value for this argument then a non-null value should also be provided for `acr_name` argument AND a value should NOT be provided for `image_server` argument."
  type        = string
  default     = null
}

variable "registry_login_server" {
  description = "Login server of the Docker registry into which the ACA app will login to pull the image whose full name is given by this argument together with image_repository and image_tag (the full name would be <registry_login_server>.<image_repository>:<image_tag>). Thus this argument is also a prefix of the full image name before the first slash e.g. in mcr.microsoft.com/k8se/quickstart:latest the image server is mcr.microsoft.com. This argument and the pair of arguments `acr_name` and `acr_resource_group_name` are mutually exclusive. EITHER provide a non-null value for this argument, OR for both of the other two, BUT NOT BOTH SETS OF ARGUMENTS. This argument would only be used if `acr_name` is null."
  type        = string
  default     = null
}

variable "registry_username" {
  description = "Username for the Docker registry to deploy to. If this argument is null then managed identity specified by managed_identity_name would be used to login to the registry."
  type        = string
  default     = null
}

variable "vault_secretname_registry_password_or_token" {
  description = "Name of the key vault secret that would contain the password or token for the Docker registry to deploy to. This would be used together with registry_username to log in to the registry if registry_username is not null."
  type        = string
  default     = null
}

variable "registry_password_or_token" {
  description = "The password or token for the Docker registry to deploy to. This would be stored in key vault secret name in argument vault_secretname_registry_password_or_token and used together with registry_username by ACA app to log in to the registry if registry_username is not null."
  type        = string
  sensitive   = true
  default     = null
}

variable "image_repository" {
  description = "Name of the Docker image to deploy, excluding the prefix which is registry_login_server (or, if acr_name is not null then the login server of the ACR instance whose name is provided in acr_name argument), and the ':<image_tag>' suffix. For example in mcr.microsoft.com/k8se/quickstart:latest the image repository is k8se/quickstart"
  type        = string
}

variable "image_tag" {
  description = "tag of the image whose name is provided in `image_repository`. This is the part of the image name after `:`. For example in image name mcr.microsoft.com/k8se/quickstart:latest, the tag is latest."
  type        = string
}

variable "app_revision_mode" {
  description = "revision mode of the container app"
  type        = string

  # # better practice for revision mode to be "Multiple"
  # # but "Single" is a simpler default
  # default = "Single"
}

variable "managed_identity_name" {
  description = "Name of the user-assigned managed identity that would be assigned to the ACA app. This would be used to read secret values from Azure Key Vault. Moreover, if acr_name parameter is not null then the managed identity named by this argument - if this argument is not null - would be used to pull image from the specified Azure Container Regitry."

  type = string

}

variable "managed_identity_resource_group_name" {
  description = "Name of the resource group in which the user-assigned managed identity exists."
  type        = string
}

variable "vault_name" {
  description = "The name of the key vault from which secrets required by the app will be read."
  type        = string
}

variable "vault_resource_group_name" {
  description = "The name of the resource group that contains the key vault."
  type        = string
}

# Variables for configuration specific to application logic
############################################################

# TODO: Make passing of secrets and non-secret
# config keys and values to the deployed app generic
# This would make the module reusable and publishable.
variable "vault_secretname_connectionstring_for_api" {
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

##########

# variable "blue-version-number" {
#     description = "SemVer version number of the last deployment to the Blue environment"
#     type = string

# }

# variable "green-version-number" {
#     description = "SemVer version number of the last deployment to the Green environment"
#     type = string

# }

# variable "production-env" {
#     description = "Label - either `blue` or `green` - of the environment that is currently live"
#     type = string
#     default = "blue"
# }
