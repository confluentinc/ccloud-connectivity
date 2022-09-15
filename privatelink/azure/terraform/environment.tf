resource "confluent_environment" "env" {
  display_name = "${var.env_name}"

  lifecycle {
    prevent_destroy = true
  }

}

resource "confluent_network" "azure-private-link" {
  display_name     = "${var.network_name}"
  cloud            = "AZURE"
  region           = "${var.region}"
  connection_types = ["PRIVATELINK"]
  environment {
    id = confluent_environment.env.id
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "confluent_private_link_access" "azure" {
  display_name = "Azure Private Link Access"
  azure {
    subscription = "${var.subscription}"
  }
  environment {
    id = confluent_environment.env.id
  }
  network {
    id = confluent_network.azure-private-link.id
  }

  lifecycle {
    prevent_destroy = true
  }
}

