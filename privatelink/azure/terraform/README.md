# privatelink/azure/terraform

Use the supplied `terraform.tfvars` file to supply required parameters to
setup your VNET for Confluent Cloud Private Link.

After populating it, simply run terraform (https://www.terraform.io/):

    terraform init
    terraform apply

The `privatelink_service_alias` is provided to you directly from Confluent.

## Issues

Currently depends on fixed behavior associated with these two upstream pull
requests:

- https://github.com/terraform-providers/terraform-provider-azurerm/pull/9793
- https://github.com/terraform-providers/terraform-provider-azurerm/pull/9794

A custom compiled binary is available here:

- https://github.com/confluentinc/terraform-provider-azurerm/releases/tag/v2.39.0-confluent-fixed

To use:

```
terraform init
mv ~/Downloads/terraform-provider-azurerm .terraform/plugins/linux_amd64/terraform-provider-azurerm_v2.32.0_x5
terraform init
terraform apply
```
