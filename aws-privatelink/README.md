# aws-privatelink

* The [terraform](./terraform) directory contains a method to setup an AWS
Private Link with Confluent Cloud.

* The [dns-endpoints.sh](./dns-endpoints.sh) script runs the AWS CLI
commands to emit the correct DNS Zone records for a specific VPC Endpoint.

Note: you can also run the script using Docker:

```bash
$ docker run --rm -it -v $HOME/.aws:/home/appuser/.aws vdesabou/ccloud-connectivity debug-connectivity.sh <bootstrap> <api-key>
```

* The [debug-connectivity.sh](./debug-connectivity.sh) script runs commands
that should be sent to Confluent Cloud support to assist with verification
of Private Link Setup.

Note: you can also run the script using Docker:

```bash
$ docker run --rm -it -v $HOME/.aws:/home/appuser/.aws vdesabou/ccloud-connectivity dns-endpoints.sh <VPC Endpoint>
```