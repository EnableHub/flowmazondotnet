
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  name                       = var.key_vault_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled    = true

#   access_policy {
#     tenant_id = data.azurerm_client_config.current.tenant_id
#     object_id = ???

#     key_permissions    = ???
#     secret_permissions = ???
#   }

}
