#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


if [ -n "$EKCP_PROXY" ]; then
    export https_proxy=socks5://127.0.0.1:${KUBEPROXY_PORT}
fi

domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')

mkdir -p "$CF_HOME"
cf login --skip-ssl-validation -a https://api."$domain" -u admin -p "$CLUSTER_PASSWORD" -o system
cf create-space tmp
cf target -s tmp

ok "Logged in to SCF"
