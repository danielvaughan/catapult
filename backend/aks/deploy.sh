#!/usr/bin/env bash

# Requires:
# - az credentials present

. ./defaults.sh
. ../../include/common.sh
. .envrc

if ! az account show; then
    info "Missing azure credentials, running az login…"
    # https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest#sign-in-using-a-service-principal
    az login --service-principal \
       --username "$AZURE_APP_ID" \
       --password "$AZURE_PASSWORD" \
       --tenant "$AZURE_TENANT_ID"
fi

git clone https://github.com/SUSE/cap-terraform.git
pushd cap-terraform/aks || exit

# terraform needs helm client installed and configured:
helm_init_client

SSHKEY="$(ssh-add -L | head -n 1)"
cat <<HEREDOC > terraform.tfvars
location          = "$AZURE_LOCATION"
az_resource_group = "$AZURE_RESOURCE_GROUP"
ssh_public_key    = "$SSHKEY"
agent_admin       = "$(whoami)"
client_id         = "$AZURE_APP_ID"
client_secret     = "$AZURE_PASSWORD"
cluster_labels    = { catapult-cluster = "$AKS_CLUSTER_NAME"}
azure_dns_json    = <<EOT
{
}
EOT
HEREDOC

terraform init

terraform plan -out=my-plan

terraform apply -auto-approve

# get kubectl for aks:
cp aksk8scfg "$KUBECONFIG"

# test deployment:
kubectl get svc

ROOTFS=overlay-xfs
# take first worker node as public ip:
PUBLIC_IP="$(kubectl get nodes -o json | jq -r '.items[].status.addresses[] | select(.type == "InternalIP").address' | head -n 1)"
DOMAIN="$PUBLIC_IP.$MAGICDNS"
if ! kubectl get configmap -n kube-system 2>/dev/null | grep -qi cap-values; then
    kubectl create configmap -n kube-system cap-values \
            --from-literal=garden-rootfs-driver="${ROOTFS}" \
            --from-literal=public-ip="${PUBLIC_IP}" \
            --from-literal=domain="${DOMAIN}" \
            --from-literal=platform=aks
fi

create_rolebinding() {

    kubectl create clusterrolebinding admin --clusterrole=cluster-admin --user=system:serviceaccount:kube-system:default
    kubectl create clusterrolebinding uaaadmin --clusterrole=cluster-admin --user=system:serviceaccount:uaa:default
    kubectl create clusterrolebinding scfadmin --clusterrole=cluster-admin --user=system:serviceaccount:scf:default

    kubectl apply -f - <<HEREDOC
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: cluster-admin
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - '*'
- nonResourceURLs:
  - '*'
  verbs:
  - '*'
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-system:default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: default
  namespace: kube-system
HEREDOC
}
create_rolebinding
