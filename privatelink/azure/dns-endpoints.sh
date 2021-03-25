#!/usr/bin/env bash

#
# dns-endpoints.sh
#
# Output zone records to correctly map to zonal endpoints for Confluent Cloud.
#
# Example:
#
#   % ./dns-endpoints.sh my-resource-group private-endpoint-1 private-endpoint-2 private-endpoint-3
#     *                          A    10.0.0.2 10.0.0.3 10.0.0.4
#     *.az2                      A    10.0.0.2
#     *.az1                      A    10.0.0.3
#     *.az3                      A    10.0.0.4
#
#   % ./dns-endpoints.sh my-resource-group private-endpoint-3
#     *                          A    10.0.0.4

az 1>/dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'azure-cli'"

if [[ $# -lt 2 ]]; then
    echo "usage: $0 <resource-group> <vnet-endpoint(s)..>" 1>&2
    echo ""
    echo "example: $0 resource-group private-endpoint-1 private-endpoint-2 private-endpoint-3"
    exit 1
fi

resourceGroup=$1

declare -A dnsrecord
declare allzonerecord

IFS='
'

for endpoint in "${@:2}"; do
    nicId=$(az network private-endpoint show \
        --name "$endpoint" --resource-group "$resourceGroup" \
        --query 'networkInterfaces[0].id' | xargs echo)
    ip=$(az network nic show --ids "$nicId" \
        --query 'ipConfigurations[0].privateIpAddress' | xargs echo)

    zoneName=$(echo "$endpoint" | sed -E -e 's/^[^-]*-[^-]*-([^.]*)$/\1/')
    zoneId="az$zoneName"
    dnsrecord[$zoneId]=$ip

    allzonerecord+=("$ip")
done

# shellcheck disable=SC2059
fmt="  %-25s A      %s\n"
if [[ ${#dnsrecord[@]} -gt 1 ]]; then # multi-zone
    printf "$fmt" "*" "$(sort <<<${allzonerecord[*]})"
    for id in "${!dnsrecord[@]}"; do
        printf "$fmt" "$id" "${dnsrecord[$id]}"
    done
else # single-zone
    for id in "${!dnsrecord[@]}"; do
        singlezonerecord=${dnsrecord[$id]}
    done
    printf "$fmt" "*" "$singlezonerecord"
fi
