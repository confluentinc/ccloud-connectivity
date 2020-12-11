# privatelink/azure/terraform

Use the supplied `terraform.tfvars` file to supply required parameters to
setup your VNET for Confluent Cloud Private Link.

After populating it, simply run terraform (https://www.terraform.io/):

    terraform init
    terraform apply

The `privatelink_service_alias` is provided to you directly from Confluent.
