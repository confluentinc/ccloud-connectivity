terraform {
  required_version = ">= 0.12.17"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.11.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.6.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

variable "project" {
  description = "The GCP project to provision"
  type        = string
}

variable "region" {
  description = "The Region to provision"
  type        = string
}

variable "network_name" {
  description = "The Network Name to provision Private Service Connect endpoint to Confluent Cloud"
  type        = string
}

variable "subnetwork_name" {
  description = "The Subnetwork Name to provision Private Service Connect endpoint to Confluent Cloud"
  type        = string
}

variable "bootstrap" {
  description = "The bootstrap server (ie: lkc-abcde-vwxyz.us-central1.gcp.glb.confluent.cloud:9092)"
  type        = string
}

variable "psc_service_attachments_by_zone" {
  description = "A map of Zone to Service Attachment from Confluent Cloud to Private Service Connect with (provided by Confluent)"
  type        = map(string)
}

locals {
  hosted_zone = length(regexall(".glb", var.bootstrap)) > 0 ? replace(regex("^[^.]+-([0-9a-zA-Z]+[.].*):[0-9]+$", var.bootstrap)[0], "glb.", "") : regex("[.]([0-9a-zA-Z]+[.].*):[0-9]+$", var.bootstrap)[0]
  network_id  = regex("^([^.]+)[.].*", local.hosted_zone)[0]
}

data "google_compute_network" "psc_endpoint_network" {
  name     = var.network_name
  provider = google
}

data "google_compute_subnetwork" "psc_endpoint_subnetwork" {
  name     = var.subnetwork_name
  provider = google
}

resource "google_compute_address" "psc_endpoint_ip" {
  for_each = var.psc_service_attachments_by_zone

  name         = "ccloud-endpoint-ip-${local.network_id}-${each.key}"
  subnetwork   = var.subnetwork_name
  address_type = "INTERNAL"

  provider = google
}

# Private Service Connect endpoint
resource "google_compute_forwarding_rule" "psc_endpoint_ilb" {
  for_each = var.psc_service_attachments_by_zone

  name = "ccloud-endpoint-${local.network_id}-${each.key}"

  target                = each.value
  load_balancing_scheme = "" # need to override EXTERNAL default when target is a service attachment
  network               = var.network_name
  ip_address            = google_compute_address.psc_endpoint_ip[each.key].id

  provider = google
}

# Private hosted zone for Private Service Connect endpoints 
resource "google_dns_managed_zone" "psc_endpoint_hz" {
  name     = "ccloud-endpoint-zone-${local.network_id}"
  dns_name = "${local.hosted_zone}."

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = data.google_compute_network.psc_endpoint_network.id
    }
  }
}

resource "google_dns_record_set" "psc_endpoint_rs" {
  name = "*.${google_dns_managed_zone.psc_endpoint_hz.dns_name}"
  type = "A"
  ttl  = 60

  managed_zone = google_dns_managed_zone.psc_endpoint_hz.name
  rrdatas = [
    for zone, _ in var.psc_service_attachments_by_zone : google_compute_address.psc_endpoint_ip[zone].address
  ]
}

resource "google_dns_record_set" "psc_endpoint_zonal_rs" {
  for_each = var.psc_service_attachments_by_zone

  name = "*.${each.key}.${google_dns_managed_zone.psc_endpoint_hz.dns_name}"
  type = "A"
  ttl  = 60

  managed_zone = google_dns_managed_zone.psc_endpoint_hz.name
  rrdatas      = [google_compute_address.psc_endpoint_ip[each.key].address]
}

resource "google_compute_firewall" "allow-https-kafka" {
  name    = "ccloud-endpoint-firewall-${local.network_id}"
  network = data.google_compute_network.psc_endpoint_network.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "9092"]
  }
  
  direction          = "EGRESS"
  destination_ranges = [data.google_compute_subnetwork.psc_endpoint_subnetwork.ip_cidr_range]
}
