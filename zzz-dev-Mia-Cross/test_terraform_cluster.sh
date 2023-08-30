#!/usr/bin/env bash

###################### THIS WAY IS A WORK IN PROGRESS ######################
########################## THE START AND STOP WAY ##########################
ZONE=fr-par-2
CLUSTER_NAME=test.nonedns
KOPS_DIR=$(pwd)
OUTPUT_DIR="$KOPS_DIR"/out/$CLUSTER_NAME
if [[ $(echo $CLUSTER_NAME | grep k8s.local) == "$CLUSTER_NAME" ]]; then
  DNS_ARG=""
else
  DNS_ARG="--dns=none"
fi
ADDITIONNAL_ARGS="--node-count=10"

make kops && make kops-install

if [[ $1 == "-d" ]]; then
  cd "$OUTPUT_DIR"
  if [[ $? == 0 ]]; then
    terraform apply -destroy -input=false -auto-approve
  fi
  cd "$KOPS_DIR" || exit
  kops delete cluster "$CLUSTER_NAME" --yes
fi
if [[ $2 == "-o" ]]; then
  exit 0
fi

# Create the cluster
kops create cluster --cloud=scaleway --zones="$ZONE" --name="$CLUSTER_NAME" $DNS_ARG $ADDITIONNAL_ARGS --target=terraform --out="$OUTPUT_DIR"
cd "$OUTPUT_DIR" || exit
terraform apply -input=false -auto-approve
if [[ $? == 1 ]]; then
  terraform init
  terraform apply -input=false -auto-approve
fi
cd "$KOPS_DIR" || exit

# Update the cluster
kops update cluster "$CLUSTER_NAME" --target=terraform --out="$OUTPUT_DIR"
cd "$OUTPUT_DIR" || exit
terraform apply -input=false -auto-approve \
-replace="scaleway_instance_server.control-plane-fr-par-2-0" \
-replace="scaleway_instance_server.nodes-fr-par-2-0" \
-replace="scaleway_instance_server.nodes-fr-par-2-1" \
-replace="scaleway_instance_server.nodes-fr-par-2-2" \
-replace="scaleway_instance_server.nodes-fr-par-2-3" \
-replace="scaleway_instance_server.nodes-fr-par-2-4" \
-replace="scaleway_instance_server.nodes-fr-par-2-5" \
-replace="scaleway_instance_server.nodes-fr-par-2-6" \
-replace="scaleway_instance_server.nodes-fr-par-2-7" \
-replace="scaleway_instance_server.nodes-fr-par-2-8" \
-replace="scaleway_instance_server.nodes-fr-par-2-9"
cd "$KOPS_DIR" || exit

kops validate cluster "$CLUSTER_NAME" --wait=15m
