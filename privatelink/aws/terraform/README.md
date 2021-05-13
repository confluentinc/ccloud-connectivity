# privatelink/aws/terraform

## Terraform tfvars
Use the supplied `terraform.tfvars` file to supply required parameters to
setup your VPC for Confluent Cloud Private Link.

* region: vpc region
* vpc_id: the vpc id that you want to connect to Confluent Cloud Cluster.
* privatelink_service_name, a.k.a VPC Endpoint service: provided by Confluent Cloud UI. Cluster settings ->
  Networking tab
* bootstrap: provided by Confluent Cloud UI. Cluster settings -> General tab
* subnets_to_privatelink: you can find subnets to private link mapping
  information from your AWS console -> VPC -> subnets

## Run terraform
After populating it, simply run terraform (https://www.terraform.io/):

    terraform init
    terraform apply
