#!/usr/bin/env bash

#
# Output Terraform variable configuration to deploy GCP Private Service Connect endpoint(s).
# The endpoint(s) can then be created via Terraform under the specified GCP network and subnetwork
# with allocated IP(s)
#
# Example:
#
#   % ./tfvars-gen.sh <bootstrap> <my gcp project> <network name> <sub-network name> \
#       <service attachment URI 1> \
#       <service attachment URI 2> \
#       <service attachment URI 3>
#

function parse_zone_from_service_attachment_uri() {
    echo "$1" | awk -F/ '{print $NF}' | awk -F-service-attachment- '{print $NF}'
}

function parse_region_from_service_attachment_uri() {
    echo "$1" | awk -F/regions/ '{print $NF}' | awk -F/ '{print $1}'
}

gcloud 1>/dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'gcloud'"

if [[ $# -lt 5 ]]; then
    echo "usage: $0 <bootstrap> <my gcp project> <network name> <subnetwork name> <service attachment URI(s)...>" 1>&2
    echo ""
    echo "example: $0 lkc-1n0nvv-6k0qeg.us-central1.gcp.glb.devel.cpdev.cloud:9092 <my gcp project> <network name> <subnetwork name> <service attachment URI 1> <service attachment URI 2> <service attachment URI 3>"
    exit 1
fi

bootstrap=$1
project=$2
network=$3
subnetwork=$4
region=$(parse_region_from_service_attachment_uri "$5")

printf "%-16s = \"%s\"\n" "project" "$project"
printf "%-16s = \"%s\"\n" "region" "$region"
printf "%-16s = \"%s\"\n" "network_name" "$network"
printf "%-16s = \"%s\"\n" "subnetwork_name" "$subnetwork"
printf "%-16s = \"%s\"\n" "bootstrap" "$bootstrap"

echo "psc_service_attachments_by_zone = {"

for sa_uri in "${@:5}"; do
    printf "  \"%s\" = \"%s\"\n" "$(parse_zone_from_service_attachment_uri "$sa_uri")" "$sa_uri"
done

echo "}"
