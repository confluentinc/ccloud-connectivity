# privatelink/gcp

* The [terraform](./terraform) directory contains a method to setup an GCP
Private Service Connect Confluent Cloud.

## Setup GCP Private Service Connect endpoint with Terraform

To simplify your setup process, The [terraform](./terraform) directory contains the Terrafrom provisoning file `privatelink.tf` for you to use. To execute the file, you need first to prepare a Terraform variable file, you may run `tfvars-gen.sh` to generate the content of the variable file. 

`tfvars-gen.sh` takes Kafka bootstrap, your GCP project, network and subnetwork info along with the Confluent `Private Service Connect Service Attachment` URI as the input, it generates terrform variable file content. Following example illustrates its usage:

```
 ./tfvars-gen.sh lkc-1n0nvv-6k0qeg.us-central1.gcp.glb.confluent.cloud:9092 <my project name> <network name> <subnetwork name> \
  projects/cc-prod/regions/us-central1/serviceAttachments/s-v1d3p-service-attachment-us-central1-a \
  projects/cc-prod/regions/us-central1/serviceAttachments/s-v1d3p-service-attachment-us-central1-b \
  projects/cc-prod/regions/us-central1/serviceAttachments/s-v1d3p-service-attachment-us-central1-c > ~/psc-endpoint.tfvars
```

You may then provision `Private Service Connect endpoint` in your network as (under [terraform](./terraform) directory):
```
terraform plan -var-file ~/psc-endpoint.tfvars
terraform apply
```

## Setup GCP `Private Service Connect` endpoint manually

1. Go to Google Cloud portal, navigate to `Network Services`/`Private Service Connect` page, you can create `Private Service Connect` endpoint(s) there directly with the `Private Service Connect Service Attachment` URI information you have gathered from Confluent Cloud.
2. Use `dns-endpoints.sh` to collect IP addresses that are needed to populate private DNS zone.
3. Use the information from step 2 to create private DNS zone and populate records in Cloud DNS.

## Debug connectivity for your `Private Service Connect` setup

You may use `debug-connectivity.sh` to verify the connectivity situation. Before you use the tool, make sure that you've had an API key/secret pair ready, the API key/secret pair should be created under `Data Integration` page in Confluent Cloud portal.

We also assume that you've correctly setup `gcloud` CLI with proper permissions being granted (i.e, permission to list forwarding-rules). `debug-connectivity.sh` uses `gcloud` CLI to retrieve and check the information related to your `Private Service Connect` setup.

Following shows example ouput of a successful validation:
```
./debug-connectivity.sh lkc-1n0nvv-6k0qeg.us-central1.gcp.glb.confluent.cloud:9092 EGV3ROSCJSJSMTIW cire-obelisk-2 projects/cc-prod/regions/us-central1/serviceAttachments/s-v1d3p-service-attachment-us-central1-a projects/cc-prod/regions/us-central1/serviceAttachments/s-v1d3p-service-attachment-us-central1-b   projects/cc-prod/regions/us-central1/serviceAttachments/s-v1d3p-service-attachment-us-central1-c
API Secret (paste hidden; press enter): 

OK    https://lkc-1n0nvv-6k0qeg.us-central1.gcp.glb.confluent.cloud/kafka/v3/clusters/lkc-test
OK    https://lkaclkc-1n0nvv-6k0qeg.us-central1.gcp.glb.confluent.cloud
OK    lkc-1n0nvv-6k0qeg.us-central1.gcp.glb.confluent.cloud:9092
OK    e-0007-us-central1-a-6k0qeg.us-central1.gcp.glb.confluent.cloud:9092
OK    e-0006-us-central1-c-6k0qeg.us-central1.gcp.glb.confluent.cloud:9092
OK    e-0004-us-central1-b-6k0qeg.us-central1.gcp.glb.confluent.cloud:9092
OK    e-0005-us-central1-b-6k0qeg.us-central1.gcp.glb.confluent.cloud:9092
OK    e-0003-us-central1-c-6k0qeg.us-central1.gcp.glb.confluent.cloud:9092
OK    e-0008-us-central1-a-6k0qeg.us-central1.gcp.glb.confluent.cloud:9092
```
