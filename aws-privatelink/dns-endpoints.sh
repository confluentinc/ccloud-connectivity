#!/usr/bin/env bash

#
# dns-endpoints.sh
#
# Output zone records to correctly map to zonal endpoints for Confluent Cloud.
#
# Example:
#
#   % ./dns-endpoints.sh vpce-0123456789abcdef0
#     *                         CNAME vpce-0123456789abcdef0-01234567.vpce-svc-0123456789abcdef0.us-west-2.vpce.amazonaws.com
#     *.usw2-az2                CNAME vpce-0123456789abcdef0-01234567-us-west-2b.vpce-svc-0123456789abcdef0.us-west-2.vpce.amazonaws.com
#     *.usw2-az1                CNAME vpce-0123456789abcdef0-01234567-us-west-2a.vpce-svc-0123456789abcdef0.us-west-2.vpce.amazonaws.com
#     *.usw2-az3                CNAME vpce-0123456789abcdef0-01234567-us-west-2c.vpce-svc-0123456789abcdef0.us-west-2.vpce.amazonaws.com
#

aws 1>/dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'aws'"

if [[ $# != 1 ]]; then
    echo "usage: $0 <VPC Endpoint>" 1>&2
    echo ""
    echo "example: $0 vpce-0123456789abcdef0"
    exit 1
fi

endpoint=$1

declare -A zonemap

IFS='
'

for nameId in $(aws ec2 describe-availability-zones \
    --query 'AvailabilityZones[*].[ZoneName, ZoneId]' \
    --output text); do
    name=$(echo "$nameId" | awk '{print $1}')
    id=$(echo "$nameId" | awk '{print $2}')
    zonemap[$name]=$id
done

fmt="  %-25s CNAME %s\n"
for name in $(aws ec2 describe-vpc-endpoints \
    --vpc-endpoint-ids "$endpoint" \
    --query 'VpcEndpoints[*].DnsEntries[*].[DnsName]' \
    --output text); do
    zoneName=$(echo "$name" | sed -E -e 's/\..*/./' -e 's/^[^-]*-[^-]*-[^-]*-?([^.]*)?\./\1/')
    if [[ -z $zoneName ]]; then
        # shellcheck disable=SC2059
        printf "$fmt" "*" "$name"
    else
        # shellcheck disable=SC2059
        printf "$fmt" "*.${zonemap[$zoneName]}" "$name"
    fi
done
