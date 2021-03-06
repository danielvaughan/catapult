#!/usr/bin/env bash

# Requires:
# - gcloud credentials present

. ../../include/common.sh

set -exuo pipefail


if [ -d "$BUILD_DIR" ]; then
    . .envrc

    if [ -d "cap-terraform/gke" ]; then
        pushd cap-terraform/gke || exit
        terraform destroy -auto-approve
        popd || exit
    fi

    popd || exit
    rm -rf "$BUILD_DIR"
fi
