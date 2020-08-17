# aws-privatelink

The [terraform](./terraform) directory contains a method to setup an AWS
Private Link with Confluent Cloud.

The [dns-endpoints.sh](./dns-endpoints.sh) script runs the AWS CLI
commands to emit the correct DNS Zone records for a specific VPC Endpoint.

The [debug-connectivity.sh](./debug-connectivity.sh) script runs commands
that should be sent to Confluent Cloud support to assist with verification
of Private Link Setup.
