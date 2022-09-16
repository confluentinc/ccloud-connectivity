data "azurerm_resource_group" "rg" {
  name = var.resource_group
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "subnet" {
  count = length(data.azurerm_virtual_network.vnet.subnets)
  name = data.azurerm_virtual_network.vnet.subnets[count.index]

  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "confluent_environment" "env" {
  display_name = "${var.env_name}"
}
