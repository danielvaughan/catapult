#!/bin/bash

set -ex 

. scripts/include/common.sh
. .envrc

helm repo add suse https://kubernetes-charts.suse.com/

helm install suse/console \
    --name susecf-console \
    --namespace stratos \
    --values scf-config-values.yaml

bash "$ROOT_DIR"/scripts/include/wait_ns.sh stratos
