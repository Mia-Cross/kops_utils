#!/usr/bin/bash

KOPS_DIR=$(pwd)
LOGS_DIR="$KOPS_DIR/logs"
TOTAL_LOG="$KOPS_DIR/total.log"
if [[ $1 != "-d" && $1 != "-td" ]]; then
  rm "$TOTAL_LOG"
  touch "$TOTAL_LOG"
fi

TEST_SCRIPTS_DIR="/home/leila/Desktop/kops_utils/zzz-dev-Mia-Cross"
EXEC="$TEST_SCRIPTS_DIR/cluster_test_loop.sh"

CLUSTER_NAME_SUFFIXES=("nonedns" "k8s.local" "leila.sieben.fr")
CLUSTER_TYPES=("NONE DNS" "GOSSIP DNS" "SCALEWAY DNS")

TEST_PREFIXES=("simple" "more-workers" "more-masters" "add-worker-igs" "add-master-igs")
TEST_NAMES=("SIMPLE --> Create / Validate / Delete on success" "MORE WORKERS --> Create with 10 workers / Validate / Delete on success" "MORE MASTERS --> Create with 3 masters / Validate / Delete on success" "+ WORKER IGS --> Create / Add worker IGs / Validate / Delete on success" "+ MASTER IGS --> Create / Validate / Add master IGs / Validate / Delete on success")
TEST_ARGS=("-c -v" "-c -v" "-c -v" "-c -a node -v" "-c -v -a master -v")
TEST_ADDITIONAL_ARGS=("" "--node-count=10" "--control-plane-count=3" "" "")

print_cluster_banner() {
  echo "****************************************************************************************************"
  echo "                                    TESTING $1 CLUSTER"
  echo "****************************************************************************************************"
}

print_test_banner() {
  echo "----------------------------------------------------------------------------------------------------"
  echo "         TEST: $1"
  echo "----------------------------------------------------------------------------------------------------"
}

create_log_file() {
  LOG_FILE=$KOPS_DIR/log-$CLUSTER_NAME.log
  rm -f "$LOG_FILE"
  touch "$LOG_FILE"
}

log_result() {
  printf '%s:\t' "$CLUSTER_NAME"
  if [ "$(cat $LOG_FILE | grep "Your cluster $CLUSTER_NAME is ready")" != "" ]; then
    printf "OK"
  else
    printf "FAIL"
  fi
  printf "\n"
}

sweep() {
  if [[ "$1" == "-t" ]]; then
  "$EXEC" -n "$CLUSTER_NAME" -t -d
  else
  "$EXEC" -n "$CLUSTER_NAME" -d
  fi
}

build_and_validate_cluster() {
  if [[ $2 == "true" ]]; then
    ARGS=("-t")
  else
    ARGS=()
  fi
  ARGS+=(${TEST_ARGS[$1]})
  ADDITIONAL_ARGS=(${TEST_ADDITIONAL_ARGS[$1]})
  if [[ ${#ADDITIONAL_ARGS[@]} == 0 ]]; then
    "$EXEC" -n "$CLUSTER_NAME" ${ARGS[*]}
  else
    ADDITIONAL_ARGS=(${ADDITIONAL_ARGS[*]}) "$EXEC" -n "$CLUSTER_NAME" ${ARGS[*]}
  fi
}

i=0
for suffix in ${CLUSTER_NAME_SUFFIXES[*]};
do
  print_cluster_banner "${CLUSTER_TYPES[$i]}"
  j=0
  for prefix in ${TEST_PREFIXES[*]};
  do
    CLUSTER_NAME="$prefix.$suffix"

    if [[ $1 == "-d" ]]; then
      sweep
      continue
    elif [[ $1 == "-td" ]]; then
      sweep "-t"
      continue

    elif [[ $1 == "-t" ]]; then
      TF="true"
      if [[ $j == 4 ]]; then
        break
      fi
    else
      TF="false"
    fi

    create_log_file
    print_test_banner "${TEST_NAMES[$j]}" | tee -a "$LOG_FILE"
    build_and_validate_cluster $j $TF >> "$LOG_FILE"
    sweep >> "$LOG_FILE"
    log_result >> "$TOTAL_LOG"

    j=$((j+1))

  done

  i=$((i+1))

done


#print_banner "FORCE ROLLING-UPDATE"
#"$EXEC" -n $1 -m -c -v -r "--force" -v
#print_banner "CLOUDONLY ROLLING-UPDATE"
#"$EXEC" -n $1 -d -c -r "--cloudonly" -v

#"$EXEC" -n $1 -m -t -c -u "" -r "--cloudonly" -v