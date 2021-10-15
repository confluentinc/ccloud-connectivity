terraform {
  required_version = ">= 0.12.17"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.55.0"
    }
  }
}

provider "azurerm" {
  features {
  }
}

variable "resource_group" {
  description = "Resource group of the VNET"
  type        = string
}

variable "region" {
  description = "The Azure Region of the existing VNET"
  type        = string
}

variable "vnet_name" {
  description = "The VNET Name to private link to Confluent Cloud"
  type        = string
}

variable "bootstrap" {
  description = "The bootstrap server (ie: lkc-abcde-vwxyz.centralus.azure.glb.confluent.cloud:9092)"
  type        = string
}

variable "privatelink_service_alias_by_zone" {
  description = "A map of Zone to Service Alias from Confluent Cloud to Private Link with (provided by Confluent)"
  type        = map(string)
}

variable "subnet_name_by_zone" {
  description = "A map of Zone to Subnet Name"
  type        = map(string)
}

locals {
  hosted_zone = replace(regex("^[^.]+-([0-9a-zA-Z]+[.].*):[0-9]+$", var.bootstrap)[0], "glb.", "")
  network_id = regex("^([^.]+)[.].*", local.hosted_zone)[0]
}


data "azurerm_resource_group" "rg" {
  name = var.resource_group
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "subnet" {
  for_each = var.subnet_name_by_zone

  name                 = each.value
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

locals {
  assert_no_network_policies_enabled = length([
    for _, subnet in data.azurerm_subnet.subnet:
    true if !subnet.enforce_private_link_endpoint_network_policies
  ]) > 0 ? file("\n\nerror: private link endpoint network policies must be disabled https://docs.microsoft.com/en-us/azure/private-link/disable-private-endpoint-network-policy") : ""
}

resource "azurerm_private_dns_zone" "hz" {
  resource_group_name = data.azurerm_resource_group.rg.name

  name = local.hosted_zone
}

resource "azurerm_private_endpoint" "endpoint" {
  for_each = var.privatelink_service_alias_by_zone

  name                = "confluent-${local.network_id}-${each.key}"
  location            = var.region
  resource_group_name = data.azurerm_resource_group.rg.name

  subnet_id = data.azurerm_subnet.subnet[each.key].id

  private_service_connection {
    name                              = "confluent-${local.network_id}-${each.key}"
    is_manual_connection              = true
    private_connection_resource_alias = each.value
    request_message                   = "PL"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "hz" {
  name                  = data.azurerm_virtual_network.vnet.name
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.hz.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_a_record" "rr" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.hz.name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 60
  records             = [
    for _, ep in azurerm_private_endpoint.endpoint: ep.private_service_connection[0].private_ip_address
  ]
}

resource "azurerm_private_dns_a_record" "zonal" {
  for_each = var.privatelink_service_alias_by_zone

  name                = "*.az${each.key}"
  zone_name           = azurerm_private_dns_zone.hz.name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 60
  records             = [
    azurerm_private_endpoint.endpoint[each.key].private_service_connection[0].private_ip_address,
  ]
}
