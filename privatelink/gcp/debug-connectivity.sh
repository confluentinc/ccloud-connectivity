#!/usr/bin/env bash

#
# debug-connectivity.sh
#
# Debug connectivity through GCP Private Service Connect to Confluent Cloud. Ensures
# alignment of zones across customer and Confluent Accounts.
#
# Prerequisite
#   The machine that runs debug-connectivity should be granted permission to list forwarding-rules
#
# Example:
#
#   % debug-connectivity.sh lkc-8wy7j0-4kxnm.centralus.azure.glb.confluent.cloud:9092 QVZ72AZWH4DRNOZT \
#       <my gcp project> \
#       <service attachment 1> \
#       <service attachment 2> \
#       <service attachment 3>
#  
#
#   API Secret (paste hidden; press enter):
#
#   OK    https://lkc-8wy7j0-4kxnm.centralus.azure.glb.confluent.cloud/kafka/v3/clusters/lkc-test
#   OK    lkc-8wy7j0-4kxnm.centralus.azure.glb.confluent.cloud:9092
#   OK    e-0011-az1-4kxnm.centralus.azure.glb.confluent.cloud:9092
#   OK    e-0013-az3-4kxnm.centralus.azure.glb.confluent.cloud:9092
#   OK    e-0015-az2-4kxnm.centralus.azure.glb.confluent.cloud:9092
#   OK    e-0016-az2-4kxnm.centralus.azure.glb.confluent.cloud:9092
#   OK    e-0014-az3-4kxnm.centralus.azure.glb.confluent.cloud:9092
#   OK    e-0012-az1-4kxnm.centralus.azure.glb.confluent.cloud:9092

function parse_zone_from_service_attachment_uri() {
    echo "$1" | awk -F/ '{print $NF}' | awk -F-service-attachment- '{print $NF}'
}

function parse_region_from_service_attachment_uri() {
    echo "$1" | awk -F/regions/ '{print $NF}' | awk -F/ '{print $1}'
}

kafkacat 1> /dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'kafkacat'"

dig 1>/dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'dig'"

openssl version 1>/dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'openssl'"

gcloud 1>/dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'gcloud'"

curl 1>/dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'curl'"

if [[ $# -lt 4 ]]; then
    echo "usage: $0 <bootstrap> <api-key> <gcp project> <service attachment1> <service attachment2> <service attachment3>" 1>&2
    echo "" 1>&2
    echo "example: $0 lkc-pj5zxy-pdzwl6.us-central1.gcp.glb.confluent.cloud:9092 QVZ72AZWH4DRNOZT my-gcp-project ..."
    echo "api-secret input via prompt" 1>&2
    echo "" 1>&2
    exit 1
fi

bootstrap=$1
key=$2
project=$3

#           lkc-py7g5-4ny6k.us-west-2.aws.glb.confluent.cloud:9092
# yields              4ny6k.us-west-2.aws.confluent.cloud
hz=$(echo "$bootstrap" | sed -E -e 's/^[^-]*-[^-]*-([^-]*-?[^.]*\.[^:]*):.*/\1/' -e 's/\.glb//')

if ! [[ $bootstrap =~ : ]]; then
    echo "error: bootstrap missing port ($bootstrap, no :9092 for example)" 1>&2
    exit 1
fi

printf 'API Secret (paste hidden; press enter): '
stty -echo; trap 'stty echo' EXIT
read -r secret
printf '\n'
stty echo; trap - EXIT

echo

IFS='
'

# create map of zoneName to IP
# ie: {rr: 10.0.0.2 10.0.0.3 10.0.0.4, us-central1-a: 10.0.0.2, us-central1-b: 10.0.0.3, us-central1-c: 10.0.0.4, ...}
declare -A endpointmap
declare allzonerecord

for ((i=4; i<= $#; i++))
do
    sa_uri="${!i}"
    zone_name=$(parse_zone_from_service_attachment_uri "$sa_uri")
    endpoint_ip=$(gcloud --project "$project" compute forwarding-rules list --filter="target:$sa_uri" --format='value(IPAddress)')

    endpointmap[$zone_name]=$endpoint_ip
    allzonerecord+=("$endpoint_ip")    
done

endpointmap["rr"]=$(sort <<<"${allzonerecord[*]}" | xargs)

fmt="%-5s %s\n"

#
# verify https path is functional
#

# shellcheck disable=SC2001
httpsname="https://$(echo "$bootstrap" | sed -e 's/:.*//')/kafka/v3/clusters/lkc-test"
httpsout=$(curl --silent --include --connect-timeout 15 "$httpsname")
httpsexpected="HTTP/1.1 401 Unauthorized"
httpsactual="$(echo "$httpsout" | grep HTTP/ | tr -d '\r')"
# shellcheck disable=SC2181
if [[ $? != 0 ]] || [[ "$httpsactual" != "$httpsexpected" ]]; then
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
        zoneName="rr"
    else
        zoneName=$(echo "$namePort" | sed -E -e 's/\..*/./' -e 's/^(lkc-[^-][^-]*|e)-[^-][^-]*-([^.][^.]*)-[^-][^-]*$/\2/')
        if [[ -z $zoneName ]]; then
            echo "error: unable to find zone name from broker name"
            exit 1
        fi
    fi

    expectedIPs=${endpointmap[$zoneName]}
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
        if [[ $zoneName == "rr" ]]; then
            printf "    \"*.%s\" should have a CNAME pointing to zone-less Private Service Connect Endpoint (resolves to \"%s\", but expected \"%s\")\n\n" \
                "${hz}" \
                "${ips}" \
                "${expectedIPs}"
        else
            printf "    \"*.%s.%s\" should have a CNAME pointing to zonal Private Service Connect Endpoint (resolves to \"%s\", but expected \"%s\")\n\n" \
                "${zoneName}" \
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
