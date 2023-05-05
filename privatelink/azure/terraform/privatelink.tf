terraform {
  required_version = ">= 0.12.17"
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


resource "azurerm_private_dns_zone" "hz" {
  name = local.hosted_zone
  resource_group_name = data.azurerm_resource_group.rg.name

  tags = {
    owner_email = "${var.owner_email}"
    purpose = "${var.purpose}"
  }

  # Uncomment if you don't want cluster to be destroyed
  # lifecycle {
  #  prevent_destroy = true
  # }
}

resource "azurerm_private_endpoint" "endpoint" {
  for_each = confluent_network.azure-private-link.azure[0].private_link_service_aliases

  name                = "confluent-${local.network_id}-${each.key}"
  location            = var.region
  resource_group_name = data.azurerm_resource_group.rg.name

  subnet_id = data.azurerm_subnet.subnet[each.key].id

  private_service_connection {
    name                              = "confluent-${local.network_id}-${each.key}"
    is_manual_connection              = true
    private_connection_resource_alias = each.value
    request_message                   = "PL request by ${var.owner_email} for ${var.purpose}"
  }

  tags = {
    owner_email = "${var.owner_email}"
    purpose = "${var.purpose}"
  }

  # Uncomment if you don't want cluster to be destroyed
  # lifecycle {
  #  prevent_destroy = true
  # }
}

resource "azurerm_private_dns_zone_virtual_network_link" "hz" {
  name                  = data.azurerm_virtual_network.vnet.name
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.hz.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id

  # Uncomment if you don't want cluster to be destroyed
  # lifecycle {
  #  prevent_destroy = true
  # }
}

resource "azurerm_private_dns_a_record" "rr" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.hz.name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 60
  records             = [
    for _, ep in azurerm_private_endpoint.endpoint: ep.private_service_connection[0].private_ip_address
  ]

  # Uncomment if you don't want cluster to be destroyed
  # lifecycle {
  #  prevent_destroy = true
  # }
}

resource "azurerm_private_dns_a_record" "zonal" {
  for_each = azurerm_private_endpoint.endpoint

  name                = "*.az${each.key}"
  zone_name           = azurerm_private_dns_zone.hz.name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 60
  records             = [
    azurerm_private_endpoint.endpoint[each.key].private_service_connection[0].private_ip_address,
  ]

  # Uncomment if you don't want cluster to be destroyed
  # lifecycle {
  #  prevent_destroy = true
  # }
}
