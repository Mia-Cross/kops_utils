#!/usr/bin/bash

SPEC_FILES_DIR="zzz-dev-Mia-Cross/cluster-spec-files"
KOPS_DIR=$(pwd)
KOPS="$KOPS_DIR/.build/dist/linux/amd64/kops"
ZONE="$S3_REGION-1"
#ADDITIONAL_ARGS=("--control-plane-count=3")
#ADDITIONAL_ARGS=("--node-count=5")

apply_terraform() {
  CMD=("terraform" "apply" "-input=false" "-auto-approve")
  cd "$OUTPUT_DIR" || exit
#  if [ "$1" == "replace" ]; then
#    TF_SERVERS=$(grep 'resource "scaleway_instance_server"' < kubernetes.tf | awk '{print $3}' | cut -d'"' -f 2)
#    for server in $TF_SERVERS; do
#      CMD+=("-replace=scaleway_instance_server.$server")
#    done
#  fi
  echo "${CMD[*]}"

  ${CMD[*]}
  if [[ $? == 1 ]]; then
    terraform init || print_error_and_exit "ERROR INITIALIZING TERRAFORM"
    ${CMD[*]} || print_error_and_exit "ERROR APPLYING TERRAFORM CLUSTER"
  fi
  cd "$KOPS_DIR" || exit
}

delete_cluster() {
  CMD=("delete" "cluster" "--name=$CLUSTER_NAME" "--yes")
  if [ "$TERRAFORM" == true ]; then
    if cd "$OUTPUT_DIR"; then
      terraform apply -destroy -input=false -auto-approve
    fi
    cd "$KOPS_DIR" || exit
  fi
  print_banner "DELETING CLUSTER" "${CMD[*]}"
  $KOPS ${CMD[*]} || print_error_and_exit "ERROR DELETING" "$1" "CLUSTER"
}

create_cluster() {
  CMD=("create" "cluster" "--name=$CLUSTER_NAME" "--cloud=scaleway" "--zones=$ZONE" "$DNS_ARG")
  CMD+=(${ADDITIONAL_ARGS[@]})
  if [ "$TERRAFORM" == true ]; then
    CMD+=(${TERRAFORM_ARGS[@]})
  else
    CMD+=("--yes")
  fi
  print_banner "CREATING CLUSTER" "${CMD[*]}"
  $KOPS ${CMD[*]} || print_error_and_exit "ERROR CREATING CLUSTER"
  if [ "$TERRAFORM" == true ]; then
    apply_terraform
    if [[ $(echo $CLUSTER_NAME | grep ".leila.sieben.fr") == "" ]]; then
      sleep 5
      update_cluster
      rolling_update_cluster "--cloudonly"
    fi
  fi
}

validate_cluster() {
  CMD=("validate" "cluster" "--name=$CLUSTER_NAME" "--wait=20m")
  print_banner "VALIDATING CLUSTER" "${CMD[*]}"
  $KOPS ${CMD[*]}
#    if [[ $? != 0 ]]; then
#      unset CMD[${#CMD[@]}]
#      $KOPS ${CMD[*]}
#      print_error_and_exit "COULD NOT VALIDATE CLUSTER WITHIN 20MIN"
#    else
#      unset CMD[${#CMD[@]}]
#      $KOPS ${CMD[*]}
#    fi
}

update_cluster() {
  CMD=("update" "cluster" "--name=$CLUSTER_NAME")
  if [ "$TERRAFORM" == true ]; then
    CMD+=(${TERRAFORM_ARGS[@]})
  else
    CMD+=("--yes")
  fi
  print_banner "UPDATING CLUSTER" "${CMD[*]}"
  $KOPS ${CMD[*]} || print_error_and_exit "ERROR UPDATING CLUSTER"
  if [ "$TERRAFORM" == true ]; then
    apply_terraform
  fi
}

rolling_update_cluster() {
  CMD=("rolling-update" "cluster" "--name=$CLUSTER_NAME" "$1" "--yes")
  print_banner "ROLLING-UPDATE" "${CMD[*]}"
  $KOPS ${CMD[*]} || print_error_and_exit "ERROR DURING ROLLING-UPDATE"

  if [[ "$TERRAFORM" == true ]]; then
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
      if [ "$NEW_SERVER_ID" == "" ]; then
        echo "could not find new ID of the server $SERVER"
      fi
      terraform import scaleway_instance_server.$SERVER $ZONE/$NEW_SERVER_ID
    done
  fi
}

replace_conf_file() {
  CMD=("replace" "-f" "$SPEC_FILES_DIR/$CLUSTER_NAME-$1.yaml")
  $KOPS ${CMD[*]} || print_error_and_exit "ERROR REPLACING CLUSTER SPEC FILE $SPEC_FILES_DIR/$CLUSTER_NAME-$1.yaml"
}

add_instance_group() {
  CMD=("create" "instancegroup" "--name=$CLUSTER_NAME" "$1" "--role=$2" "--subnet=$ZONE"  "--edit=false")
  $KOPS ${CMD[*]} || print_error_and_exit "ERROR CREATING INSTANCE GROUP $1"
}

delete_instance_group() {
  CMD=("delete" "instancegroup" "--name=$CLUSTER_NAME" "$1" "--yes")
  $KOPS ${CMD[*]} || print_error_and_exit "ERROR DELETING INSTANCE GROUP $1"
}

print_help() {
  echo "Usage: $(basename $0) -n <cluster_name> [-m] [-t] [-d] [-c] [-v] [-a] [-u] [-r] [-w]"
  echo "m: make: builds kops"
  echo "t: terraform target"
  echo "d: deletes the previous cluster"
  echo "c: creates the cluster"
  echo "v: validates the cluster"
  echo "a master|node: adds extra IGs to the cluster"
  echo "u: updates the cluster"
  echo "r --cloudonly|\"\": does a rolling-update, cloudonly if specified"
  echo "w: wipes the cluster at the end of the run"
}

print_banner() {
  TITLE=$1
  CMD_ARGS=$2
  printf "\n**********************************************************************************************\n"
  printf "\t%s\n" "$TITLE"
  printf "kops %s\n" "${CMD_ARGS[*]}"
  printf "**********************************************************************************************\n\n"
}

print_error_and_exit() {
  echo "$1"
  exit 1
}


########################################################################################################################

if [ "$SCW_ACCESS_KEY" == "" ] || [ "$KOPS_STATE_STORE" == "" ]; then
  print_error_and_exit "ENVIRONMENT VARIABLES ARE NOT SET !!"
fi

while getopts 'n:mtdcva:ur:wh:' opt; do
  case "$opt" in
    n)
      CLUSTER_NAME="$OPTARG"
      if [[ $(echo "$CLUSTER_NAME" | grep "nonedns") == "$CLUSTER_NAME" ]]; then
        DNS_ARG="--dns=none"
      fi
      ;;
    m)
      make kops
      if [ $? != 0 ]; then
        echo "ERROR BUILDING KOPS"
        exit 1
      fi
      ;;
    t)
      TERRAFORM=true
      OUTPUT_DIR="$KOPS_DIR/out/$CLUSTER_NAME"
      TERRAFORM_ARGS=("--target=terraform" "--out=$OUTPUT_DIR")
      ;;
    l)
      LOG=true
      ;;
    d)
      delete_cluster "PREVIOUS"
      ;;
    c)
      create_cluster
      ;;
    v)
      validate_cluster
      ;;
    a)
      role="$OPTARG"
      if [ $role == "master" ]; then
        replace_conf_file "extra_masters"
        add_instance_group "master2" "master"
        add_instance_group "master3" "master"
        update_cluster
        rolling_update_cluster "--cloudonly"
      elif [ $role == "node" ]; then
        add_instance_group "node2" "node"
        add_instance_group "node3" "node"
        add_instance_group "node4" "node"
        add_instance_group "node5" "node"
        update_cluster
      else
        echo "Must specify the role of the IG to add. Must be one of master or node"
        exit 1
      fi
      ;;
    u)
      update_cluster
      ;;
    r)
      rolling_update_cluster "$OPTARG"
      ;;
    w)
      if [ "$OPTARG" == "" ]; then
        delete_cluster
      else
        read -r -p "Are you ready to delete $CLUSTER_NAME ? y or n" input
        if [[ $input == "y" ]] ; then
          delete_cluster
        fi
      fi
      ;;
    h)
      print_help
      exit 0
      ;;
    :)
      echo -e "Option requires an argument. "
      print_help
      exit 1
      ;;
    ?)
      echo -e "Invalid command: "
      print_help
      exit 1
      ;;
  esac
done
#shift "$(($OPTIND -1))"
