resource "confluent_service_account" "app-ksql" {
  display_name = "${var.ksql_app_id}"
  description  = "Service account to manage ${var.ksql_cluster} ksqlDB cluster"
}

resource "confluent_role_binding" "app-ksql-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-ksql.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.dedicated.rbac_crn
}

resource "confluent_ksql_cluster" "ksql" {
  display_name = "${var.ksql_cluster}"
  csu          = 1
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }
  credential_identity {
    id = confluent_service_account.app-ksql.id
  }
  environment {
    id = data.confluent_environment.env.id
  }
  depends_on = [
    confluent_role_binding.app-ksql-kafka-cluster-admin
  ]
}