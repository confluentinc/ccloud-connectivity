variable "region" {
  description = "The AWS Region of the existing VPC"
  type        = string
}

variable "customer_vpc_id" {
  description = "The customer's VPC ID to private link to Confluent Cloud"
  type        = string
}

variable "confluent_vpc_id" {
  description = "The Confluent's VPC ID (provided by Confluent under Network Management tab)"
  type        = string
}

variable "confluent_cidr" {
  description = "The Confluent's VPC's CIDR (provided by Confluent under Network Management tab)"
  type        = string
}
