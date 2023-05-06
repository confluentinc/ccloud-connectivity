resource_group = "my-resource-group"
region         = "centralus"
vnet_name      = "my-vnet-name"
bootstrap      = "lkc-abc123-def45.centralus.azure.glb.confluent.cloud:9092"
privatelink_service_alias_by_zone = {
  "1" = "s-ghi67-privatelink-1.01234567-890a-bcde-f012-34567890abcd.centralus.azure.privatelinkservice",
  "2" = "s-ghi67-privatelink-2.01234567-890a-bcde-f012-34567890abcd.centralus.azure.privatelinkservice",
  "3" = "s-ghi67-privatelink-3.01234567-890a-bcde-f012-34567890abcd.centralus.azure.privatelinkservice",
}
subnet_name_by_zone = {
  "1" = "default",
  "2" = "default",
  "3" = "default",
}
