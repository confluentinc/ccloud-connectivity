#!/usr/bin/env bash

#
# debug-connectivity.sh
#
# Debug connectivity through AWS Private Link to Confluent Cloud.
#
# Example:
#
#   % debug-connectivity.sh lkc-3gyjw-l63jl.us-west-2.aws.glb.confluent.cloud:9092 QVZ72AZWH4DRNOZT
#   API Secret (paste hidden; press enter):
#
#   Bootstrap should have 3 IPs; Brokers should have 1 IP; Example good output:
#   lkc-3gyjw-l63jl.us-west-2.aws.glb.confluent.cloud:9092 lkc-3gyjw.l63jl.us-west-2.aws.confluent.cloud. vpce-0123456789abcdef0-01234567.vpce-svc-0123456789abcdef0.us-west-2.vpce.amazonaws.com. 10.1.9.41 10.1.25.219 10.1.33.5 -----BEGIN CERTIFICATE----- Verify return code: 0 (ok)
#   e-07cc-usw2-az1-l63jl.us-west-2.aws.glb.confluent.cloud:9092 e-07cc.usw2-az1.l63jl.us-west-2.aws.confluent.cloud. vpce-0123456789abcdef0-01234567-us-west-2a.vpce-svc-0123456789abcdef0.us-west-2.vpce.amazonaws.com. 10.1.9.41 -----BEGIN CERTIFICATE----- Verify return code: 0 (ok)
#
#   ...
#

kafkacat 1> /dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'kafkacat'"

dig 1>/dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'dig'"

openssl version 1>/dev/null 2>/dev/null
[[ $? == 127 ]] && echo "warning: please install 'openssl'"

if [[ $# != 2 ]]; then
    echo "usage: $0 <bootstrap> <api-key>" 1>&2
    echo "" 1>&2
    echo "api-secret input via prompt" 1>&2
    echo "" 1>&2
    exit 1
fi

bootstrap=$1
key=$2

printf 'API Secret (paste hidden; press enter): '
stty -echo; trap 'stty echo' EXIT
read -r secret
printf '\n'
stty echo; trap - EXIT

IFS='
'

echo
echo "Bootstrap should have 3 IPs; Brokers should have 1 IP; Example good output:"
cat <<EOF
lkc-3gyjw-l63jl.us-west-2.aws.glb.confluent.cloud:9092 lkc-3gyjw.l63jl.us-west-2.aws.confluent.cloud. vpce-0123456789abcdef0-01234567.vpce-svc-0123456789abcdef0.us-west-2.vpce.amazonaws.com. 10.1.9.41 10.1.25.219 10.1.33.5 -----BEGIN CERTIFICATE----- Verify return code: 0 (ok)
e-07cc-usw2-az1-l63jl.us-west-2.aws.glb.confluent.cloud:9092 e-07cc.usw2-az1.l63jl.us-west-2.aws.confluent.cloud. vpce-0123456789abcdef0-01234567-us-west-2a.vpce-svc-0123456789abcdef0.us-west-2.vpce.amazonaws.com. 10.1.9.41 -----BEGIN CERTIFICATE----- Verify return code: 0 (ok)
EOF
echo
echo
for namePort in $bootstrap $(kafkacat \
    -X security.protocol=SASL_SSL \
    -X "sasl.username=$key" \
    -X "sasl.password=$secret" \
    -X sasl.mechanisms=PLAIN \
    -X api.version.request=true \
    -b "$bootstrap" \
    -L | grep ' at ' | sed -e 's/.* at //'); do

    name=$(echo "$namePort" | awk -F: '{print $1}')
    # shellcheck disable=SC2046
    echo "$namePort" $(dig +short "$name") $(openssl s_client -connect "$namePort" -servername "$name" </dev/null 2>/dev/null | grep -E 'BEGIN CERTIFICATE|Verify return code' | xargs)
done
