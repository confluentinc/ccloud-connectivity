terraform {
  required_version = ">= 0.12.17"
}

provider "google" {
  project     = var.customer_project
  region      = var.region
}

variable "peer_name" {
    description = "The name of this network peer"
    type = string
}
variable "customer_project" {
    description = "The GCP project in the customer account"
    type = string
}

variable "region" {
    description = "GCP region"
    type = string
}

variable "customer_vpc" {
    description = "The name of the cusotmer VPC"
    type = string
}

variable "confluent_vpc" {
    description = "Confluent VPC name (available on the networking tab of the cluster setting page)"
    type = string
}

variable "confluent_project" {
    description = "Confluent Project (available on the networking tab of the cluster setting page"
    type = string
}

resource "google_compute_network_peering" "peering" {
    name            = var.peer_name
    network         = "projects/${var.customer_project}/global/networks/${var.customer_vpc}"
    peer_network    = "projects/${var.confluent_project}/global/networks/${var.confluent_vpc}"
}
