terraform {
  required_version = ">= 0.13.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 2.32.0"
    }
  }
}

# https://docs.confluent.io/cloud/current/networking/peering/aws-peering.html
# Create a VPC Peering Connection to Confluent Cloud on AWS
provider "aws" {
  region = var.region
}

# Customer's side of the connection.
data "aws_vpc_peering_connection" "accepter" {
  vpc_id      = var.confluent_vpc_id
  peer_vpc_id = var.customer_vpc_id
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = data.aws_vpc_peering_connection.accepter.id
  auto_accept               = true
}

data "aws_vpc" "customer_vpc" {
  id = var.customer_vpc_id
}

resource "aws_route" "r" {
  route_table_id            = data.aws_vpc.customer_vpc.main_route_table_id
  destination_cidr_block    = var.confluent_cidr
  vpc_peering_connection_id = data.aws_vpc_peering_connection.accepter.id

  depends_on = [
    aws_vpc_peering_connection_accepter.peer
  ]
}
