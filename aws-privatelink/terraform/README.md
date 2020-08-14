# aws-privatelink/terraform

Use the supplied `terraform.tfvars` file to supply required parameters to
setup your VPC for Confluent Cloud Private Link.

After populating it, simply run terraform (https://www.terraform.io/):

    terraform init
    terraform apply

The `privatelink_service_name` is provided to you directly from Confluent.
