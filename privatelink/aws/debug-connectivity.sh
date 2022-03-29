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
#   OK    https://lkc-3gyjw-l63jl.us-west-2.aws.glb.confluent.cloud/kafka/v3/clusters/lkc-test
#   OK    https://lkaclkc-3gyjw-l63jl.us-west-2.aws.glb.confluent.cloud
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

curl 1>/dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'curl'"

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
#           lkc-py7g5-4ny6k.us-west-2.aws.glb.confluent.cloud:9092
# yields              4ny6k.us-west-2.aws.confluent.cloud
hz=$(echo "$bootstrap" | sed -E -e 's/^[^-]*-[^-]*-([^-]*-?[^.]*\.[^:]*):.*/\1/' -e 's/\.glb//')

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

#
# verify https path is functional
#

# shellcheck disable=SC2001
httpsname="https://$(echo "$bootstrap" | sed -e 's/:.*//')/kafka/v3/clusters/lkc-test"
httpsout=$(curl --silent --include "$httpsname")
httpsexpected="HTTP/.* 401"
httpsactual="$(echo "$httpsout" | grep HTTP/ | tr -d '\r')"
# shellcheck disable=SC2181
if [[ $? != 0 ]] || [[ ! "$httpsactual" =~ $httpsexpected ]]; then
    # shellcheck disable=SC2059
    printf "$fmt" "FAIL" "$httpsname"
    printf "    unexpected output from https endpoint (received \"%s\", expected \"%s\")\n\n" "$httpsactual" "$httpsexpected"
else
    # shellcheck disable=SC2059
    printf "$fmt" "OK" "$httpsname"
fi

# shellcheck disable=SC2001
httpsname="https://$(echo "$bootstrap" | sed -e 's/:.*//;s/lkc-/lkaclkc-/')"
httpsout=$(curl --silent --include "$httpsname")
httpsexpected="HTTP/.* 401"
httpsactual="$(echo "$httpsout" | grep HTTP/ | tr -d '\r')"
# shellcheck disable=SC2181
if [[ $? != 0 ]] || [[ ! "$httpsactual" =~ $httpsexpected ]]; then
    # shellcheck disable=SC2059
    printf "$fmt" "FAIL" "$httpsname"
    printf "    unexpected output from https endpoint (received \"%s\", expected \"%s\")\n\n" "$httpsactual" "$httpsexpected"
else
    # shellcheck disable=SC2059
    printf "$fmt" "OK" "$httpsname"
fi

#
# verify kafka bootstrap/broker paths are functional
#

kcatout=$(kafkacat \
    -X security.protocol=SASL_SSL \
    -X "sasl.username=$key" \
    -X "sasl.password=$secret" \
    -X sasl.mechanisms=PLAIN \
    -X api.version.request=true \
    -b "$bootstrap" \
    -L)
kcatrc=$?
brokers=$(echo "$kcatout" | grep ' at ' | sed -e 's/.* at //' -e 's/ .*//' | tr -d '\r')

if (( kcatrc != 0 )); then
    echo "error: kafkacat exited non-zero $kcatrc" 1>&2
    echo ""
    echo "$kcatout"
    exit 1
fi

nendpoints=0
for namePort in $bootstrap $brokers; do
    nendpoints=$(( nendpoints + 1 ))
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
            printf "    unable to connect, firewall/security group? (received \"%s\", expected \"%s\")\n\n" "$connectivity" "$expectedConnectivity"
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

if (( nendpoints <= 1 )); then
    echo "error: expected more than 1 endpoint to be tested; missing brokers?" 1>&2
    exit 1
fi
