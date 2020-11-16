#!/usr/bin/env bash

#
# debug-connectivity.sh
#
# Debug connectivity through AWS Private Link to Confluent Cloud. Ensures
# alignment of zones across customer and Confluent Accounts.
#
# Example:
#
#   % debug-connectivity.sh vpce-0123456789abcdef0 lkc-3gyjw-l63jl.us-west-2.aws.glb.confluent.cloud:9092 QVZ72AZWH4DRNOZT
#   API Secret (paste hidden; press enter):
#
#   OK    lkc-3gyjw-l63jl.us-west-2.aws.glb.confluent.cloud:9092
#   OK    e-0cb9-usw2-az1-l63jl.us-west-2.aws.glb.confluent.cloud:9092
#   OK    e-24ab-usw2-az3-l63jl.us-west-2.aws.glb.confluent.cloud:9092
#   OK    e-1f75-usw2-az2-l63jl.us-west-2.aws.glb.confluent.cloud:9092
#   OK    e-1b28-usw2-az2-l63jl.us-west-2.aws.glb.confluent.cloud:9092
#   OK    e-25b1-usw2-az3-l63jl.us-west-2.aws.glb.confluent.cloud:9092
#   OK    e-0ebc-usw2-az1-l63jl.us-west-2.aws.glb.confluent.cloud:9092
#

kafkacat 1> /dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'kafkacat'"

dig 1>/dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'dig'"

openssl version 1>/dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'openssl'"

aws 1>/dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'aws'"

if [[ $# != 3 ]]; then
    echo "usage: $0 <vpc-endpoint> <bootstrap> <api-key>" 1>&2
    echo "" 1>&2
    echo "example: $0 vpce-0123456789abcdef0 lkc-3gyjw-l63jl.us-west-2.aws.glb.confluent.cloud:9092 QVZ72AZWH4DRNOZT"
    echo "api-secret input via prompt" 1>&2
    echo "" 1>&2
    exit 1
fi

endpoint=$1
bootstrap=$2
key=$3
#           lkc-py7g5-4ny6k.us-west-2.aws.glb.confluent.cloud
# yields              4ny6k.us-west-2.aws.confluent.cloud
hz=$(echo "$bootstrap" | sed -E -e 's/^[^-]*-[^-]*-([^-]*-?[^.]*?\.[^:]*):.*/\1/' -e 's/\.glb//')

if ! [[ $bootstrap =~ : ]]; then
    echo "error: bootstrap missing port ($bootstrap, no :9092 for example)" 1>&2
    exit 1
fi

declare -A zonemap
declare -A endpointmap

printf 'API Secret (paste hidden; press enter): '
stty -echo; trap 'stty echo' EXIT
read -r secret
printf '\n'
stty echo; trap - EXIT

echo

IFS='
'

# create map of zoneName to zoneId
# ie: {us-west-2a: usw2-az3, us-west-2b: usw2-az1, ...}
for nameId in $(aws ec2 describe-availability-zones \
    --query 'AvailabilityZones[*].[ZoneName, ZoneId]' \
    --output text); do
    name=$(echo "$nameId" | awk '{print $1}')
    id=$(echo "$nameId" | awk '{print $2}')
    zonemap[$id]=$name
done

# inspect endpoints on VPC Endpoints
for name in $(aws ec2 describe-vpc-endpoints \
    --vpc-endpoint-ids "$endpoint" \
    --query 'VpcEndpoints[*].DnsEntries[*].[DnsName]' \
    --output text); do
    zoneName=$(echo "$name" | sed -E -e 's/\..*/./' -e 's/^[^-]*-[^-]*-[^-]*-?([^.]*)?\./\1/')
    if [[ -z $zoneName ]]; then
        endpointmap["rr"]=$(dig +short "$name" | grep -v cloud | sort | xargs)
    else
        endpointmap[$zoneName]=$(dig +short "$name" | grep -v cloud | sort | xargs)
    fi
done

fmt="%-5s %s\n"
for namePort in $bootstrap $(kafkacat \
    -X security.protocol=SASL_SSL \
    -X "sasl.username=$key" \
    -X "sasl.password=$secret" \
    -X sasl.mechanisms=PLAIN \
    -X api.version.request=true \
    -b "$bootstrap" \
    -L | grep ' at ' | sed -e 's/.* at //' -e 's/ .*//' | tr -d '\r'); do

    if [[ $namePort == "$bootstrap" ]]; then
        zoneId="rr"
        expectedIPs=${endpointmap[rr]}
    else
        zoneId=$(echo "$namePort" | sed -E -e 's/\..*/./' -e 's/^(lkc-[^-][^-]*|e)-[^-][^-]*-([^.][^.]*)-[^-][^-]*$/\2/')
        if [[ -z $zoneId ]]; then
            echo "error: unable to find zone id from broker name"
            exit 1
        fi
        expectedIPs=${endpointmap[${zonemap[$zoneId]}]}
    fi

    name=$(echo "$namePort" | awk -F: '{print $1}')
    ips=$(dig +short "$name" | grep -Ev ".cloud|.com" | sort | xargs)
    if [[ "${expectedIPs}" == "${ips}" ]]; then
        connectivity=$(openssl s_client -connect "$namePort" -servername "$name" </dev/null 2>/dev/null | grep -E 'BEGIN CERTIFICATE|Verify return code' | xargs)
        expectedConnectivity="-----BEGIN CERTIFICATE----- Verify return code: 0 (ok)"
        if [[ $connectivity == "$expectedConnectivity" ]]; then
            # shellcheck disable=SC2059
            printf "$fmt" "OK" "$namePort"
        else
            # shellcheck disable=SC2059
            printf "$fmt" "FAIL" "$namePort"
            # shellcheck disable=SC2059
            printf "    unable to connect, firewall/security group? (received \"$connectivity\", expected \"$expectedConnectivity\")\n\n"
        fi
    else
        # shellcheck disable=SC2059
        printf "$fmt" "FAIL" "$namePort"
        if [[ $zoneId == "rr" ]]; then
            printf "    \"*.%s\" should have a CNAME pointing to zone-less VPC Endpoint (resolves to \"%s\", but expected \"%s\")\n\n" \
                "${hz}" \
                "${ips}" \
                "${expectedIPs}"
        else
            printf "    \"*.%s.%s\" should have a CNAME pointing to zonal VPC Endpoint (resolves to \"%s\", but expected \"%s\")\n\n" \
                "${zoneId}" \
                "${hz}" \
                "${ips}" \
                "${expectedIPs}"
        fi
    fi
done
