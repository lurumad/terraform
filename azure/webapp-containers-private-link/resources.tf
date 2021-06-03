resource "random_string" "prefix" {
  length  = 10
  special = false
  upper   = false
}

resource "azurerm_resource_group" "group" {
  name     = "webapp-container-privatelink-rg"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "endpointsubnet" {
  name                 = "endpointsubnet"
  resource_group_name  = azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_app_service_plan" "appserviceplan" {
  name                = "${random_string.prefix.result}-plan"
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name

  sku {
    tier = "Premiumv2"
    size = "P1v2"
  }
}

resource "azurerm_app_service" "webapp" {
  name                = "${random_string.prefix.result}-webapp"
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  app_service_plan_id = azurerm_app_service_plan.appserviceplan.id
}

resource "azurerm_private_dns_zone" "dnsprivatezone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszonelink" {
  name                  = "dnszonelink"
  resource_group_name   = azurerm_resource_group.group.name
  private_dns_zone_name = azurerm_private_dns_zone.dnsprivatezone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_endpoint" "privateendpoint" {
  name                = "webappprivateendpoint"
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  subnet_id           = azurerm_subnet.endpointsubnet.id

  private_dns_zone_group {
    name                 = "privatednszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsprivatezone.id]
  }

  private_service_connection {
    name                           = "privateendpointconnection"
    private_connection_resource_id = azurerm_app_service.webapp.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}