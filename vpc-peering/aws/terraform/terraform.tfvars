# The region of the AWS peer VPC.
region = "us-east-2"

# The AWS VPC ID of the peer VPC that you're peering with Confluent Cloud.
# You can find your AWS VPC ID here (https://console.aws.amazon.com/vpc/) under Your VPCs section of the AWS Management Console. Must start with `vpc-`.
customer_vpc_id = "vpc-0b9bba0e776228180"

# "The Confluent's VPC ID (provided by Confluent under Network Management tab)"
confluent_vpc_id = "vpc-abcdef0123456789a"

# "The Confluent's VPC's CIDR (provided by Confluent under Network Management tab)"
confluent_cidr = "10.10.0.0/16"

# Add credentials and other settings to $HOME/.aws/config
# for AWS TF Provider to work: https://registry.terraform.io/providers/hashicorp/aws/latest/docs#shared-configuration-and-credentials-files

# Requirements of VPC Peering on AWS
# https://docs.confluent.io/cloud/current/networking/peering/aws-peering.html#vpc-peering-on-aws