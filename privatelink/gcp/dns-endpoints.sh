#!/usr/bin/env bash

#
# dns-endpoints.sh
#
# Output zone records to correctly map to zonal endpoints for Confluent Cloud.
#
# Example:
#
#   % ./dns-endpoints.sh lkc-1n0nvv-6k0qeg.us-central1.gcp.glb.devel.cpdev.cloud:9092 <my gcp project> <service attachment URI 1> <service attachment URI 2> <service attachment URI 3>
#
#   Hosted zone domain: 6k0qeg.us-central1.gcp.devel.cpdev.cloud
#     *                          A    10.0.0.2 10.0.0.3 10.0.0.4
#     *.us-central1-a            A    10.0.0.2
#     *.us-central1-b            A    10.0.0.3
#     *.us-central1-c            A    10.0.0.4
#
#   % ./dns-endpoints.sh lkc-1n0nvv-6k0qeg.us-central1.gcp.glb.devel.cpdev.cloud:9092 <my gcp project> <service attachment URI>
#
#   Hosted zone domain: 6k0qeg.us-central1.gcp.devel.cpdev.cloud
#     *                          A    10.0.0.4

function parse_zone_from_service_attachment_uri() {
    echo "$1" | awk -F/ '{print $NF}' | awk -F-service-attachment- '{print $NF}'
}

function parse_region_from_service_attachment_uri() {
    echo "$1" | awk -F/regions/ '{print $NF}' | awk -F/ '{print $1}'
}

function hosted_zone_domain_from_bootstrap() {
    host=$(echo "$1" | awk -F: '{print $1}')
    domain=$(echo "$host" | sed -e 's/\(.*\)\.glb\.\(.*\)/\1.\2/')
    network=$(echo "$domain" | awk -F. '{print $1}' | awk -F- '{print $NF}')
    echo "$domain" | sed -e "s/\([^\.]*\)\(\..*\)/$network\2/"  
}

gcloud 1>/dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'gcloud'"

if [[ $# -lt 3 ]]; then
    echo "usage: $0 <bootstrap> <my gcp project> <service attachment URI(s)...>" 1>&2
    echo ""
    echo "example: $0 lkc-1n0nvv-6k0qeg.us-central1.gcp.glb.devel.cpdev.cloud:9092 <my gcp project> <service attachment URI 1> <service attachment URI 2> <service attachment URI 3>"
    exit 1
fi

bootstrap=$1
project=$2

declare -A dnsrecord
declare allzonerecord

IFS='
'

for sa_uri in "${@:3}"; do
    zoneName=$(parse_zone_from_service_attachment_uri "$sa_uri")
    ip=$(gcloud --project "$project" compute forwarding-rules list --filter="target:$sa_uri" --format='value(IPAddress)')

    dnsrecord[$zoneName]=$ip

    allzonerecord+=("$ip")
done

printf "Hosted zone domain: %s\n\n" "$(hosted_zone_domain_from_bootstrap "$bootstrap")"

# shellcheck disable=SC2059
fmt="  %-25s A      %s\n"
if [[ ${#dnsrecord[@]} -gt 1 ]]; then # multi-zone
    printf "$fmt" "*" "$(sort <<<${allzonerecord[*]} | xargs)"
    for id in "${!dnsrecord[@]}"; do
        printf "$fmt" "*.$id" "${dnsrecord[$id]}"
    done
else # single-zone
    for id in "${!dnsrecord[@]}"; do
        singlezonerecord=${dnsrecord[$id]}
    done
    printf "$fmt" "*" "$singlezonerecord"
fi
