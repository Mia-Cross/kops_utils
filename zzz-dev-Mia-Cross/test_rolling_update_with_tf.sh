#!/usr/bin/env bash

########################### THIS WAY WORKS ###########################
####################### THE ROLLING-UPDATE WAY #######################
ZONE=fr-par-2
CLUSTER_NAME=test-ru.nonedns
KOPS_DIR=$(pwd)
OUTPUT_DIR="$KOPS_DIR"/out/$CLUSTER_NAME
if [[ $(echo $CLUSTER_NAME | grep k8s.local) == "$CLUSTER_NAME" ]]; then
  DNS_ARG=""
else
  DNS_ARG="--dns=none"
fi
#ADDITIONAL_ARGS="--node-count=10 --master-count=1"

make kops && make kops-install

if [[ $1 == "-d" ]]; then
  cd "$OUTPUT_DIR" || exit
  terraform apply -destroy -input=false -auto-approve || exit
  cd "$KOPS_DIR" || exit
  kops delete cluster "$CLUSTER_NAME" --yes || exit
fi
if [[ $2 == "-o" ]]; then
  exit 0
fi

# Create the cluster
kops create cluster --cloud=scaleway --zones="$ZONE" --name="$CLUSTER_NAME" $DNS_ARG --target=terraform --out="$OUTPUT_DIR" || exit
cd "$OUTPUT_DIR" || exit
terraform apply -input=false -auto-approve || exit
if [[ $? == 1 ]]; then
  terraform init || exit
  terraform apply -input=false -auto-approve || exit
fi
cd "$KOPS_DIR" || exit

# Update the cluster
kops update cluster "$CLUSTER_NAME" --target=terraform --out="$OUTPUT_DIR" || exit
cd "$OUTPUT_DIR" || exit
terraform apply -input=false -auto-approve || exit
cd "$KOPS_DIR" || exit

# Rolling-update
kops rolling-update cluster "$CLUSTER_NAME" --cloudonly --yes || exit

# Replace instances in the state
cd "$OUTPUT_DIR" || exit
TF_SERVERS=($(grep 'resource "scaleway_instance_server"' < kubernetes.tf | awk '{print $3}' | cut -d'"' -f 2))
if [ ${#TF_SERVERS[@]} -lt 2 ]; then
  echo "Only got ${#TF_SERVERS[@]} servers in TF file"
  exit 1
fi
ZONE=$(terraform output zone | cut -d '"' -f2)
for SERVER in "${TF_SERVERS[@]}"; do
  terraform state rm scaleway_instance_server.$SERVER
  NEW_SERVER_ID=$(scw instance server list zone=$ZONE name=$SERVER -o template="{{ .ID }}")
  echo $SERVER " --- " $NEW_SERVER_ID
  if [ $NEW_SERVER_ID == "" ]; then
    echo "could not find new ID of the server $SERVER"
  fi
  terraform import scaleway_instance_server.$SERVER $ZONE/$NEW_SERVER_ID
done

#kops validate cluster "$CLUSTER_NAME" --wait=10m
