variable "owner_email" {
  description = "Owner Email"
  type        = string
}

variable "purpose" {
  description = "Purpose"
  type        = string
}

variable "env_name" {
  description = "Confluent Cloud Environment Name"
  type        = string
}

variable "cluster_name" {
  description = "Confluent Cloud Cluster Name"
  type        = string
}

variable "network_name" {
  description = "Confluent Cloud Network Name"
  type        = string
}

variable "subscription" {
  description = "Azure Subscription"
  type        = string
}

variable "region" {
  description = "Azure Region"
  type        = string
}

variable "resource_group" {
  description = "Resource group of the VNET"
  type        = string
}

variable "vnet_name" {
  description = "The VNET Name to private link to Confluent Cloud"
  type        = string
}

locals {
  hosted_zone = replace(regex("^[^.]+-([0-9a-zA-Z]+[.].*):[0-9]+$", confluent_kafka_cluster.dedicated.bootstrap_endpoint)[0], "glb.", "")
  network_id = regex("^([^.]+)[.].*", local.hosted_zone)[0]
}
