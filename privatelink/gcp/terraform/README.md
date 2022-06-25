# privatelink/gcp/terraform

Use the supplied `terraform.tfvars` file to supply required parameters to
setup your network for Confluent Cloud Private Link.

After populating it, simply run terraform (https://www.terraform.io/):

    terraform init
    terraform apply

The `psc_service_attachment` is provided to you directly from Confluent.
