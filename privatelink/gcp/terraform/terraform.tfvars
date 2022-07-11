project         = "your-gcp-project-here"
region          = "us-central1"
network_name    = "your-network-name-here"
subnetwork_name = "your-subnetwork-name-here"
bootstrap       = "lkc-1n0nvv-6k0qeg.us-central1.gcp.glb.confluent.cloud:9092"
psc_service_attachments_by_zone = {
  "us-central1-a" = "projects/cc-prod/regions/us-central1/serviceAttachments/s-v1d3p-service-attachment-us-central1-a",
  "us-central1-b" = "projects/cc-prod/regions/us-central1/serviceAttachments/s-v1d3p-service-attachment-us-central1-b",
  "us-central1-c" = "projects/cc-prod/regions/us-central1/serviceAttachments/s-v1d3p-service-attachment-us-central1-c",
}
