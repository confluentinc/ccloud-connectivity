resource "confluent_network" "azure-private-link" {
  display_name     = "${var.network_name}"
  cloud            = "AZURE"
  region           = "${var.region}"
  connection_types = ["PRIVATELINK"]
  environment {
    id = data.confluent_environment.env.id
  }

  # Uncomment if you don't want cluster to be destroyed
  # lifecycle {
  #  prevent_destroy = true
  # }
}

resource "confluent_private_link_access" "azure" {
  display_name = "Azure Private Link Access"
  azure {
    subscription = "${var.subscription}"
  }
  environment {
    id = data.confluent_environment.env.id
  }
  network {
    id = confluent_network.azure-private-link.id
  }

  # Uncomment if you don't want cluster to be destroyed
  # lifecycle {
  #  prevent_destroy = true
  # }
}

