// Output

output "azurerm_virtual_network_vnet_id" {
 value = [data.azurerm_virtual_network.vnet.id]
}

output "azurerm_virtual_network_vnet_address_space" {
 value = [data.azurerm_virtual_network.vnet.address_space]
}

output "azurerm_virtual_network_vnet_subnet" {
 value = [data.azurerm_virtual_network.vnet.subnets]
}

output "ccloud_env_id" {
  value = [data.confluent_environment.env.id]
}

output "ccloud_env_resource_name" {
  value = [data.confluent_environment.env.resource_name]
}

output "ccloud_network_id" {
  value = [confluent_network.azure-private-link.id]
}

output "ccloud_network_resource_name" {
  value = [confluent_network.azure-private-link.resource_name]
}

output "ccloud_network_dns_domain" {
  value = [confluent_network.azure-private-link.dns_domain]
}

output "ccloud_network_zonal_subdomains" {
  value = [confluent_network.azure-private-link.zonal_subdomains]
}

output "ccloud_network_private_link_service_aliases" {
  value = [confluent_network.azure-private-link.azure[*].private_link_service_aliases]
}

output "ccloud_kafka_cluster_dedicated_id" {
  value = [confluent_kafka_cluster.dedicated.id]
}

output "ccloud_kafka_cluster_dedicated_bootstrap_endpoint" {
  value = [confluent_kafka_cluster.dedicated.bootstrap_endpoint]
}

output "ccloud_kafka_cluster_dedicated_rest_endpoint" {
  value = [confluent_kafka_cluster.dedicated.rest_endpoint]
}

output "azurerm_private_dns_zone_hz_id" {
  value = [azurerm_private_dns_zone.hz.id]
}

output "azurerm_private_dns_zone_hz_soa_record" {
  value = [azurerm_private_dns_zone.hz.soa_record]
}

output "azurerm_private_endpoint_endpoint" {
  value = [azurerm_private_endpoint.endpoint[*]]
}

output "azurerm_private_dns_zone_virtual_network_link_hz" {
  value = [azurerm_private_dns_zone_virtual_network_link.hz]
}

output "azurerm_private_dns_a_record_rr" {
  value = [azurerm_private_dns_a_record.rr]
}

output "azurerm_private_dns_a_record_zonal" {
  value = [azurerm_private_dns_a_record.zonal]
}
