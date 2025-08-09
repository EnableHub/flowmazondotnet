module "aca_app" {
  source                        = "git::https://github.com/EnableHub/flowmazondotnet.git//.iac/modules/aca_app?ref=main"
  app_resource_group_name       = var.app_resource_group_name
  app_resource_group_location   = var.app_resource_group_location
  app_name                      = var.app_name
  app_environment_name          = var.app_environment_name
  app_domain_name               = var.app_domain_name
  app_container_name            = var.app_container_name
  app_container_port            = var.app_container_port
  app_container_max_replicas    = var.app_container_max_replicas
  app_container_liveness_probe  = "/health/live"
  app_container_readiness_probe = "/health/ready"

  # Given the definition of liveness probe in the
  # ASP.NET Core API (flowmazonapi), it is stronger than def of livenvess
  # probe for an ACA app and meets the definition of startup
  # probe of an ACA app. 
  # Hence why we have used it in both places.
  app_container_startup_probe = "/health/live"

  env_OTEL_EXPORTER_OTLP_ENDPOINT                 = var.env_OTEL_EXPORTER_OTLP_ENDPOINT
  env_OTEL_EXPORTER_OTLP_HEADERS                  = var.env_OTEL_EXPORTER_OTLP_HEADERS
  vault_secretname_env_OTEL_EXPORTER_OTLP_HEADERS = var.vault_secretname_env_OTEL_EXPORTER_OTLP_HEADERS
  env_OTEL_RESOURCE_ATTRIBUTES                    = var.env_OTEL_RESOURCE_ATTRIBUTES
  env_OTEL_EXPORTER_OTLP_PROTOCOL                 = var.env_OTEL_EXPORTER_OTLP_PROTOCOL



  acr_name = var.acr_name

  acr_resource_group_name              = var.acr_resource_group_name
  image_repository                     = var.image_repository
  image_tag                            = var.image_tag
  app_revision_mode                    = "Multiple"
  managed_identity_name                = var.managed_identity_name
  managed_identity_resource_group_name = var.id_and_vault_resource_group_name

  vault_name = var.key_vault_name

  vault_resource_group_name = var.id_and_vault_resource_group_name

  vault_secretname_connectionstring_for_api = var.vault_secretname_for_connectionstring

  allowed_cors_origins_for_api = var.allowed_cors_origins_for_api
  cloudflare_api_token         = var.cloudflare_api_token
  cloudflare_zone_id           = var.cloudflare_zone_id

  providers = {
    restful.cloudflare = restful.cloudflare
  }
}
