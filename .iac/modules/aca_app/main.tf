
data "azurerm_resource_group" "vault" {
  name = var.vault_resource_group_name

}

data "azurerm_resource_group" "registry" {
  count = var.acr_name != null ? 1 : 0
  name  = var.acr_resource_group_name

}

data "azurerm_resource_group" "managed_identity" {
  name = var.managed_identity_resource_group_name

}

data "azurerm_user_assigned_identity" "managed_identity" {
  name                = var.managed_identity_name
  resource_group_name = data.azurerm_resource_group.managed_identity.name
}

data "azurerm_container_registry" "app" {
  count               = var.acr_name != null ? 1 : 0
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.registry[0].name
}

data "azurerm_key_vault" "vault" {
  name                = var.vault_name
  resource_group_name = data.azurerm_resource_group.vault.name
}

data "azurerm_key_vault_secret" "connstr_for_api" {
  name         = var.vault_secretname_connectionstring_for_api
  key_vault_id = data.azurerm_key_vault.vault.id
}

locals {
  login_server    = var.acr_name != null ? data.azurerm_container_registry.app[0].login_server : var.registry_login_server
  full_image_name = "${local.login_server}/${var.image_repository}:${var.image_tag}"
}

resource "azurerm_resource_group" "app" {
  name     = var.app_resource_group_name
  location = var.app_resource_group_location
}

resource "azurerm_container_app_environment" "app" {
  name                = var.app_environment_name
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name

}

# Create key vault secret for env_OTLP_EXPORTER_OTLP_HEADERS.
# Doing so means the value of the variables wouldn't be visible
# in Azure.
resource "azurerm_key_vault_secret" "otlp_headers" {
  name         = var.vault_secretname_env_OTEL_EXPORTER_OTLP_HEADERS
  key_vault_id = data.azurerm_key_vault.vault.id
  value        = var.env_OTEL_EXPORTER_OTLP_HEADERS
}

resource "azurerm_key_vault_secret" "registry_password_or_token" {
  name         = var.vault_secretname_registry_password_or_token
  key_vault_id = data.azurerm_key_vault.vault.id
  value        = var.registry_password_or_token
}



resource "azurerm_container_app" "app" {
  name                         = var.app_name
  container_app_environment_id = azurerm_container_app_environment.app.id
  resource_group_name          = azurerm_resource_group.app.name
  revision_mode                = var.app_revision_mode
  max_inactive_revisions       = 4 #because default is ~100 and ther IS a (small) charge for inactive revsions


  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = var.app_container_port
    client_certificate_mode    = "accept" # doesn't require a client certificate to be presented but wouldn't return an error if one is presented by the client.


    dynamic "ip_security_restriction" {
      for_each = local.cloudflare_ips

      content {
        # want to generate a unique name for the 
        # ip range. Better practice with dynamically
        # generated blocks to do this than to 
        # assign index 1...n that we could have
        # done with count instead of for-each
        # as we have done in this dynamic block
        name             = "Allow-Cloudflare-${replace(replace(replace(ip_security_restriction.value, ".", "-"), ":", "--"), "/", "_")}"
        description      = "One of the CloudFlare's outbound IP ranges. Part of a fairly stable set of IPs."
        ip_address_range = ip_security_restriction.value
        action           = "Allow"
      }
    }

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }

    # Note this ingress would need to have a custom domain binding
    # but we only add it (see use of azapi resources below to do 
    # that) once DNS records (CNAME and TXT) have been created
    # at CloudFlare and have propagated.
    # If we do it now we would get an error.
    #
    # I have verified that once the custom domain has been created,
    # subsequent `terraform apply` operations DO NOT detect
    # the addition of custom domain to this ingress as drift and
    # try to deleted it. So we're ok.
  }

  registry {

    server               = var.acr_name != null ? data.azurerm_container_registry.app[0].login_server : var.registry_login_server
    identity             = var.registry_username == null ? data.azurerm_user_assigned_identity.managed_identity.id : null
    username             = var.registry_username
    password_secret_name = var.registry_username == null ? null : var.vault_secretname_registry_password_or_token


  }

  secret {
    name     = var.vault_secretname_registry_password_or_token
    identity = data.azurerm_user_assigned_identity.managed_identity.id
    # key_vault_secret_id is mandatory together with name above
    key_vault_secret_id = azurerm_key_vault_secret.registry_password_or_token.id
  }

  # like the vault_secretname_env_OTEL_EXPORTER_OTLP_HEADERS
  # secret below, this would loaded into an env 
  # block (corresponding to an environment variable
  # passed to ACA app at run time) in this resource.
  secret {
    name     = var.vault_secretname_connectionstring_for_api
    identity = data.azurerm_user_assigned_identity.managed_identity.id
    # key_vault_secret_id is mandatory together with name above
    key_vault_secret_id = data.azurerm_key_vault_secret.connstr_for_api.id
  }

  # Reference secret in key vault that stores value of 
  # env_OTEL_EXPORTER_OTLP_HEADERS argument of this
  # module. (we created this secret above). 
  # We would later set this referenced secret as value
  # of an environmentr variable on the app.
  secret {
    name     = var.vault_secretname_env_OTEL_EXPORTER_OTLP_HEADERS
    identity = data.azurerm_user_assigned_identity.managed_identity.id
    # key_vault_secret_id is mandatory together with name above
    key_vault_secret_id = azurerm_key_vault_secret.otlp_headers.id
  }

  identity {
    # it is possible for a service to have both. I am giving it 
    # both.
    # This is because while we need the UserAssigned identity to 
    # let the app access the key vault and ACR etc, the 
    # automatically created and assigned system-assigned identity
    # of the app may be used in authN/authZ with ACA app environment
    # which we have created in a way that its settings would be 
    # autogenerated and would not be changeable after creation.
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.managed_identity.id]

  }

  template {
    max_replicas = var.app_container_max_replicas
    container {
      name   = var.app_container_name
      image  = local.full_image_name
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = local.allowed_cors_origins_env_var_name
        value = var.allowed_cors_origins_for_api
      }
      env {
        name = local.connection_string_env_var_name
        # We don't want to set it from the value of the secret
        # read from key vault (the account executing this terraform
        # config may not even have the permission to do that).value
        #
        # If we did that, the value would be visible in 
        # Environment Variables section of the app in plain text
        #
        # Therefore we simply provide the name of the secret
        # we want the value to be retrieved from.
        #
        # For this to work, we need to reference the secret
        # in a secret object in the app object (done above),
        # which in turn requries a reference to a
        # azurerm_key_vault_secret data source and for that a
        # azurerm_key_vault data source.
        secret_name = var.vault_secretname_connectionstring_for_api
      }

      # ENVIROINMENT VARS FOR OTEL CONFIGURATION
      #################################################
      # We did not configure ACA App environment's Otel
      # collector because that can only send telemetry
      # using gRPC whereas Gafana Cloud's OTLP endpoint
      # to which it would write only support HTTP with 
      # Protocol Buffers (http/protobuf), as the following
      # links show:
      #
      # https://grafana.com/docs/grafana-cloud/send-data/otlp/otlp-format-considerations/
      #
      # https://learn.microsoft.com/en-us/azure/container-apps/opentelemetry-agents?tabs=terraform%2Cbicep-example#known-limitations

      env {
        name  = "OTEL_RESOURCE_ATTRIBUTES"
        value = var.env_OTEL_RESOURCE_ATTRIBUTES
      }
      env {
        name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
        value = var.env_OTEL_EXPORTER_OTLP_ENDPOINT
      }
      env {
        name  = "OTEL_EXPORTER_OTLP_PROTOCOL"
        value = var.env_OTEL_EXPORTER_OTLP_PROTOCOL
      }
      env {
        name        = "OTEL_EXPORTER_OTLP_HEADERS"
        secret_name = var.vault_secretname_env_OTEL_EXPORTER_OTLP_HEADERS
      }

      dynamic "liveness_probe" {
        for_each = var.app_container_liveness_probe != null ? [1] : []
        content {
          transport = "HTTP"
          port      = var.app_container_port
          path      = var.app_container_liveness_probe
        }
      }

      dynamic "readiness_probe" {
        for_each = var.app_container_readiness_probe != null ? [1] : []
        content {
          transport = "HTTP"
          port      = var.app_container_port
          path      = var.app_container_readiness_probe
        }
      }

      # because of the way liveness probe is implemented in 
      # the ASP.NET Core API, the liveness probe only
      # responds with Healthy and 2xx if 
      # startup has completed. So we are using it as
      # startup_probe also
      dynamic "startup_probe" {
        for_each = var.app_container_startup_probe != null ? [1] : []
        content {
          transport = "HTTP"
          port      = var.app_container_port
          path      = var.app_container_startup_probe
        }
      }
    }
  }
}

# Create DNS settings in CloudFlare

# PREREQUISITE: CloudFlare's namesrevers should already been rwgistered 
# with the Domain Name Registrar you bought the domain name from.
# This would have created a Zone in CLoudFlare for your apex domain
# e.g. `efast.uk`

# returns cloudflare's ip ranges so we can add them to ingress allow rules
# in ACA app
data "cloudflare_ip_ranges" "cloudflare" {}

locals {

  # Create a set of Cloudflare IPv4 IPs which we 
  # will put in the allow list of the container app's ingress
  cloudflare_ips = toset(data.cloudflare_ip_ranges.cloudflare.ipv4_cidrs)

  subdomain  = split(".", var.app_domain_name)[0]                              # e.g., 'api' for 'api.efast.uk'
  apexdomain = trimprefix(var.app_domain_name, format("%s.", local.subdomain)) # e.g., 'efast.uk'

  # this is what we would create a TXT record with for the app's domain name 
  custom_domain_verification_id = azurerm_container_app.app.custom_domain_verification_id

}

# To map the API's domain name to your ACA app, we need to create
# a CNAME record and a TXT record. This is normally done for the
# subdomain part of the app's domain name (for example create a 
# CNAME record for `api` and TXT record for `asuid.api` where the
# domain name of the app is api.efast.uk).
#
# HOWEVER, with CLoudFlare's Terraform resources, you have to
# provide the full domain name (FQDN, e.g. api.efast.uk). If 
# you only provider the prefix then it works on first apply but
# on every subsequent apply, perhaps because you made a change
# to some other resource, the cloudflare_dns_record resource
# would say there is a change and it has to change 
# the current name in the actual CloudFlare DNS record, which
# would be `api.efast.uk` for CNAME record and `asuid.api.efast.uk
# for TXT record, back to `api` and `asuid.api` respectively.
resource "cloudflare_dns_record" "app_cname" {

  zone_id = var.cloudflare_zone_id
  name    = var.app_domain_name

  # this should be the target FQDN without the `https://` prefix,
  # which is how ingress's fqdn property returns it
  content = azurerm_container_app.app.ingress[0].fqdn
  type    = "CNAME"
  ttl     = 1 # 1 means TTL is automatically set by CloudFlare


  # Setting proxied = true is what allows us to get CloudFlare
  # protections such as DDoS protection, WAF and API Shield features.
  #
  # However we need it to be false initially to allow domain
  # name verification to be successful for creating custom
  # domain binding on the app's ingress and for managed
  # certificate generation.
  # Even so, I have a restful_operation resource that, in the
  # the multi-step Cloudflare setup process (signposted below)
  # turn it off before creating custom domain binding, generating
  # managed cert and updating the custom domain binding with it.
  # Once that is done, another restful_operation would turn 
  # it back on.
  # SO I could have left proxied to true here.
  #
  # YET, the reason for leaving it to false at time of CNAME
  # record creation is that if I leave it on, then even though
  # it is later turned  off during the process and turned back
  # on again, and during this "blip", DNS record verififcation
  # happens successfully, once I turn it bacl on, it took
  # a long time, sometimes even 30 minutes, for the DNS cache
  # in Cloudflare to be flushed and the domain name to be reachable.
  # In the meantime, I would keep getting DNS_PROBE_FINISHED_NXDOMAIN
  # error in the browser.
  #
  # Now this does not happen and as soon as terraform apply has
  # finidhed, the domain is instantly reachable (although if 
  # container count is zero, it can take around 20 seconds for 
  # a new container to spinup so that request take a while
  # to complete). I have verified this by destroying and applying
  # again and again many times. After every apply, I was able 
  # to reach the domain name of the app immediately.
  proxied = false

  lifecycle {
    ignore_changes = [proxied]
  }

}

resource "cloudflare_dns_record" "app_txt" {
  zone_id = var.cloudflare_zone_id
  name    = format("%s.%s", "asuid", var.app_domain_name)
  # I think, but am not sure, that the content of TXT record 
  # must be contained within quotes. It works anyway.
  content = format("\"%s\"", local.custom_domain_verification_id)
  type    = "TXT"
  ttl     = 1 # 1 means TTL is automatically set by CloudFlare
}



# PROCESS IMPLEMENTED BELOW:
######################################################
# If source (domain name) or target (ACA app's FQDN)
# of the CNAME change - or if this is the the first
# terraform apply of the config - we need to go through
# the following steps:
#
# 1. Wait for the changes to propagate.
# 2. Set 'proxied=off' on the CNAME record. Otherwise
#   managed cert creation and almost certinly the 
#   custom domain binding creation and update would fail.
# 3. recreate the manager cert
# 4. in order to recerate the cert, we need to destroy
# any existing custom domain binding, then recreate is 
# as Disabled
# 5. Once managed cert has been created, we need to 
# update the custom domain binding with the cert.
# 6. Set proxied back on the CNAME record.
#
# PROCESS IMPLEMENATTION NOTE:
# In implementing the provess, I have borne in mind the
# details given in document
# [Terraform Core Resource Destruction Notes](https://github.com/hashicorp/terraform/blob/main/docs/destroying.md)

# This data resource to collect the key attributes of CNAME
# record that, if they change, should trigger a replace
# of the key recources that follow whose purpose is to
# suppor the above process
resource "terraform_data" "cname_and_txt_info_for_triggering_replacement" {
  input = {
    targetfqdn                    = cloudflare_dns_record.app_cname.content
    sourcefqdn                    = var.app_domain_name
    custom_domain_verification_id = local.custom_domain_verification_id
  }
}

# First we wait for the DNS records to have propagated
resource "time_sleep" "cname_and_txt_propagated" {
  create_duration = "60s" # 60 seconds always seems to work with CloudFlare

  depends_on = [cloudflare_dns_record.app_cname, cloudflare_dns_record.app_txt]

  # this argument, which predates replace_triggered_by lifecycle property,
  # requries a map of values rather than resources. So we set it to 
  # .output of the terraform_data resoruce rather than the resource itself.
  triggers = terraform_data.cname_and_txt_info_for_triggering_replacement.output
}

# Set proxied=false on the  CNAME record. 
#
# NOTE: 
# It would probably have been enough to set proxied=false in CNAME
# record resource with lifecycle.ignore_changes = ["proxied"].
# The problem with that is that if for any reason the cert or
# custom domain binding had to change or be recreated (e.g,
# we change the domain name that is the source of CNAME record,
# or the ACAP app is replaced as that would generate a new FQDN
# to set as content - i.e. target - of the CNAME record), then
# managed cert would need to be regenerated and custom domain 
# binding  updated which would fail because the last time round
# we had set `proxied==true` right at the end of the process
# when managed cert had been created and custom domain binding
# updated. 
#
# We would still set proxied=true in that way (at the end
# of the process), but we now we explicitly turn it to off
# just after updates to key data in cname or txt records
# (domain name, target of CNAME record, or TXT value) have
# occurred and propagated, and just before any updates to
# mnaged cert and custom domain binding may need to happen
# as a result.
resource "restful_operation" "turn_off_proxied_in_cname_record" {
  depends_on = [time_sleep.cname_and_txt_propagated]

  lifecycle {
    replace_triggered_by = [terraform_data.cname_and_txt_info_for_triggering_replacement]
  }

  provider = restful.cloudflare

  path   = "/zones/${cloudflare_dns_record.app_cname.zone_id}/dns_records/${cloudflare_dns_record.app_cname.id}"
  method = "PATCH"
  body   = { "proxied" : false }

  # I think we can also poll for retry. See resource
  # documentation in terraform registry (under
  # magodo/restful provider)
}

# Initialize a custom domain binding in the ingress of the app
# We can do it now, but couldn't when we created the app, because
# now the DNS records with CloudFlare would have propagated. Those
# would be validated by Azure when it creates the binding.
resource "azapi_resource_action" "custom_domain_binding_initialize" {
  depends_on = [time_sleep.cname_and_txt_propagated, restful_operation.turn_off_proxied_in_cname_record]
  lifecycle {
    # This resource does nothing on update or destroy. 
    # But we do want it to be re-created if key bits in CNAME
    # or TXT change. Hence setting replace_triggered_by below.
    #
    # During replacement, the actual destruction of the custom
    # binding that this resource creates/initialisez is achieved by
    # resource azapi_resource_action.custom_domain_binding_destroy
    # which  has been configured to ONLY operate during destroys and 
    # deletes the very custom binding that resource below initializes.
    replace_triggered_by = [terraform_data.cname_and_txt_info_for_triggering_replacement]
  }

  type        = "Microsoft.App/containerApps@2023-05-01"
  resource_id = azurerm_container_app.app.id

  # It seems `action` just gets appended to the URL obtained by
  # appending `resource_id` to the base url for the `type`
  # this gives us URLs for actions on some resources like 
  # `/start` on a Web App in an App Service Plan.
  # WE DON't WANT TO USE IT HERE
  #
  #action                 = ""


  # default for this resource is POST, unlike for the
  # azapi_update_resource for which it seems to be PATCH
  # from my Fiddler investigations
  method = "PATCH"

  body = {
    properties = {
      configuration = {
        ingress = {
          customDomains = [
            {
              bindingType = "Disabled",
              name        = var.app_domain_name,
            }
          ]
        }
      }
    }
  }
}

# azurerm can't create a managed TLS certificate - 
# see https://github.com/hashicorp/terraform-provider-azurerm/issues/21866
#
# So instead of using azurerm provider the following resources are 
# created using AzAPI provider to make directy API calls to Azure.
resource "azapi_resource" "managed_certificate" {

  depends_on = [azapi_resource_action.custom_domain_binding_initialize, time_sleep.cname_and_txt_propagated, cloudflare_dns_record.app_cname, cloudflare_dns_record.app_txt, restful_operation.turn_off_proxied_in_cname_record]

  # Unlike azapi_update_resource and azapi_resource_action, that we have used in this
  # process to patch the custom domain binding on the ingress of the ACA app
  # this resource is fully managed through create update and destroy. However,
  # an actual managed cert needs repalcement when the domain name or the FQDN
  # of the backing ACA app changes. Hence lifecycle.repalce_triggered_by below
  # is the same as that for the other azapi resources and restful_operation
  # resources used in this process.
  lifecycle {
    replace_triggered_by = [terraform_data.cname_and_txt_info_for_triggering_replacement]
  }
  type      = "Microsoft.App/managedEnvironments/managedCertificates@2023-05-01"
  name      = "${lower(var.app_name)}-cert"
  parent_id = azurerm_container_app_environment.app.id
  location  = azurerm_resource_group.app.location

  body = {
    properties = {
      subjectName             = var.app_domain_name
      domainControlValidation = "CNAME"
    }
  }

  response_export_values = ["*"]
}


# update the already-create custom domain binding in the app's ingress
# with the certificate and make the binding enabled.
resource "azapi_update_resource" "custom_domain_binding_update" {
  depends_on  = [restful_operation.turn_off_proxied_in_cname_record, azapi_resource_action.custom_domain_binding_initialize, azapi_resource.managed_certificate]
  type        = "Microsoft.App/containerApps@2023-05-01"
  resource_id = azurerm_container_app.app.id
  lifecycle {
    # this resource only operates during create and update, not destroy
    # we do want the underlying domain binding to be destroyed when
    # this resource needs to be recreated. That is acheived by the 
    # azapi_resource_action.custom_domain_binding_destroy resource
    # which would run only on destroy and delete the custom domain 
    # binding being updated by this resource.
    replace_triggered_by = [terraform_data.cname_and_txt_info_for_triggering_replacement]
  }

  body = {
    properties = {
      configuration = {
        ingress = {
          customDomains = [
            {
              bindingType   = "SniEnabled",
              name          = var.app_domain_name,
              certificateId = azapi_resource.managed_certificate.output.id
            }
          ]
        }
      }
    }
  }
}

# The azapi_update_resource that creates custom binding above works
# during create and update phases of the lifecycle. 
# However, it does nothing during destroy. This leads to a problem
# when destroying the managed cert with the error that the cert 
# is in use in a custom binding (which has not beeen destroyed).
#
# This resource does nothing during update and, depending on setting
# of 'when' argument, works either during create, or during destroy.
# We have set it to run during destroy so it destroys the 
# custom domain binding, so that the managed cert can 
# then be destroyed or the cusomt domain binding re-created by
# the recreation of custim_domain_binding_initialize and
# custom_domain_binding_update resources above in the right order.
resource "azapi_resource_action" "custom_domain_binding_destroy" {
  type = "Microsoft.App/containerApps@2023-05-01"
  lifecycle {
    replace_triggered_by = [terraform_data.cname_and_txt_info_for_triggering_replacement]
  }

  # following line also makes this resource a dependent 
  # on the custom_domain_binding_create resource.
  resource_id = azapi_update_resource.custom_domain_binding_update.resource_id

  method = "PATCH"

  response_export_values = ["*"]


  body = {
    properties = {
      configuration = {
        ingress = {
          customDomains = [] # ensures the custom domain would be deleted
        }
      }
    }
  }

  when = "destroy"
}

resource "restful_operation" "turn_on_proxied_in_cname_record" {
  depends_on = [azapi_update_resource.custom_domain_binding_update, azapi_resource.managed_certificate,

    # We know that resource named below would 
    # definitely be replaced for the same reasons as this one is.
    # However, we want to be certain that the the present resource
    # would run to turn proxied back on definitely after it has
    # been turned off. Hence the following dependency.
  restful_operation.turn_off_proxied_in_cname_record]

  lifecycle {
    replace_triggered_by = [terraform_data.cname_and_txt_info_for_triggering_replacement]
  }

  provider = restful.cloudflare

  path   = "/zones/${cloudflare_dns_record.app_cname.zone_id}/dns_records/${cloudflare_dns_record.app_cname.id}"
  method = "PATCH"
  body   = { "proxied" : true }

  # I think we can also poll for retry. See resource
  # documentation in terraform registry (under
  # magodo/restful provider)
}
