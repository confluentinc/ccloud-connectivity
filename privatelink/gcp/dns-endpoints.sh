#!/usr/bin/env bash

#
# dns-endpoints.sh
#
# Output zone records to correctly map to zonal endpoints for Confluent Cloud.
#
# Example:
#
#   % ./dns-endpoints.sh my-gcp-project lkc-abcde-vwxyz.us-central1.gcp.glb.confluent.cloud
#

gcloud 1>/dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'gcloud'"

if [[ $# -lt 2 ]]; then
    echo "usage: $0 <gcp-project> <bootstrap server>" 1>&2
    echo ""
    echo "example: $0 my-gcp-project lkc-abcde-vwxyz.us-central1.gcp.glb.confluent.cloud"
    exit 1
fi

gcp_project=$1
network_id=$(echo "$2" | awk -F. '{print $1}' | awk -F- '{print $NF}')

gcloud --project "$gcp_project" dns record-sets list --zone="ccloud-endpoint-zone-$network_id"
