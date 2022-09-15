resource "confluent_kafka_cluster" "dedicated" {
  display_name = "${var.cluster_name}"
  availability = "MULTI_ZONE"
  cloud        = "AZURE"
  region       = "${var.region}"
  dedicated {
    cku = 2
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
