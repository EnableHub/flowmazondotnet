terraform {
  required_providers {
    azurerm = {
      # Following environment variables must be provided for this provider:
      # ARM_SUBSCRIPTION_ID, ARM_CLIENT_ID, ARM_TENANT_ID, ARM_CLIENT_SECRET
      #
      # All of these - except ARM_SUBSCRIPTION_ID can be obtained when 
      # you create a service principal in Entra in Azure portal.
      #
      # For ARM_SUBSCRIPTION_ID, provide the ID of a subscription
      # in your Azure account.
      source  = "hashicorp/azurerm"
      version = "4.34.0" # Pinned to an exact version for repeatabilityneeded
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.6.0" # pinned to exact version for repeatability
    }
    azapi = {
      source  = "azure/azapi"
      version = "2.4.0" # pinned to exact version for repeatability
    }
    time = {
      source  = "hashicorp/time"
      version = "0.13.1" # pinned version for repeatability
    }
    # restapi = {
    #   source  = "Mastercard/restapi"
    #   version = "2.0.1" # version pinned for repeatability
    # }
    restful = {
      source  = "magodo/restful"
      version = "0.22.0" # version pinned for repeatability
    }

  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {

      # In Production, we configure soft delete and purge-protection
      # to enabled on key vaults, as per the best practices:
      # https://learn.microsoft.com/en-us/azure/key-vault/general/best-practices
      #      
      # "Soft-delete" means a deleted key vault would be recoverable
      # (for 90 days by default). This is a protection against
      # accidental deletin:
      # https://learn.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview#soft-delete-behavior
      #
      # Purging means to permanently delete a key vault 
      # that was already deleted but was still recoverable bu virtue of
      # the fact that it had soft-delete enabled on it.
      #
      # When "purge protection" is enabled on a key vault, this would not be 
      # possible, i.e. you would not be able to purge a soft-deleted
      # key vault. It would noly get deleted automatically after the
      # retention period, which defaults t o90 days, has elapsed, or the 
      # vaultis n longer scheduled for permanent deletion because it was
      # recovered befrooe this period elapsed.
      # https://learn.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview#purge-protection
      #
      # If soft-delete is enabled on a key vault, this provider would 
      # first delete it (this would be a soft-delete), and then 
      # purge it in order to effect complete deletion on
      # `terraform destroy`. This is because the default value
      # of the argument below, `purge_soft_delete_on_destroy`, 
      # is `true`.
      #
      # However, with the purge protection
      # enabled on key vaults we create in this configuration,
      # the provider wn't be able to do that when it tries to 
      # destroy an azurerm_key_vault resource. Therefore we
      # set this argument to false.
      purge_soft_delete_on_destroy = false

      # Given that a Production environment key vault
      # would not be permanently deleted (as described
      # above), once it has been (soft-)deleted by 
      # `terraform destroy`, I would like it to be
      # recovered when Terraform tries to create a 
      # vault with the same name in a subsequent
      # `terraform apply`. This is what setting 
      # `recover_soft_deleted_key_vaults` to true
      # achieves,as done below.
      recover_soft_deleted_key_vaults = true


      # By roughly the same reasoning as for the 
      # `purge_soft_delete_on_destroy` property above, 
      # we would enable soft-delete on individual secrets,
      # cryptographic keys and certificates in the vault,
      # and therefore set the following to true.
      purge_soft_deleted_secrets_on_destroy      = false
      purge_soft_deleted_keys_on_destroy         = false
      purge_soft_deleted_certificates_on_destroy = false

    }
  }
}

provider "azapi" {
  # this needs to the same four environment 
  # variables to be provided that we are setting
  # for the azurerm provider above

}



provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "time" {

}

# # aliasing the provider as you could have multiple
# # of these for different APIs/targets
# provider "restapi" {
#   alias = "cloudflare"
#   # Configuration options
#   uri                  = "https://api.cloudflare.com/client/v4"
#   write_returns_object = true
#   headers = {
#     Content-Type  = "application/json"
#     Authorization = "Bearer ${var.cloudflare_api_token}"
#   }
# }

provider "restful" {
  alias = "cloudflare"
  # Configuration options
  base_url = "https://api.cloudflare.com/client/v4"

  header = {
    Content-Type  = "application/json"
    Authorization = "Bearer ${var.cloudflare_api_token}"
  }
}
