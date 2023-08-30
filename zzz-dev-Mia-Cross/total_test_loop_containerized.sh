TEST_SCRIPTS_DIR=zzz-dev-Mia-Cross
BASH=$(which bash)

cleanup() {
  kops delete cluster $CLUSTER_NAME --yes >$LOG_FILE
  if [ $? != 0 ]; then
    printf "\n\nERROR DURING DESTROY, GOTTA CLEAN-UP AGAIN\n\n" >$LOG_FILE
  fi
}

validate() {
  kops create secret --name=$CLUSTER_NAME sshpublickey admin -i ~/.ssh/id_rsa.pub
  kops validate cluster $CLUSTER_NAME --wait=15m
  if [[ $? == 0 ]]; then
    printf "\n\nCLUSTER VALIDATED SUCCESSFULLY\n\n" >$LOG_FILE
  else
    printf "\n\nCOULD NOT VALIDATE CLUSTER WITHIN 10MIN\n\n" >$LOG_FILE
  fi
}

echo "****************************************************************************************************"
echo "                                    TESTING GOSSIP DNS CLUSTER"
echo "****************************************************************************************************"
CLUSTER_NAME="total.k8s.local"
LOG_FILE="log-gossip.txt"

cleanup
kops create cluster --cloud=scaleway --zones=pl-waw-1 --name=$CLUSTER_NAME --networking=cilium \
  --cloud-labels="containerized=true" --yes >$LOG_FILE
validate
cleanup

printf "\n\n"
echo "****************************************************************************************************"
echo "                                    TESTING DNS CLUSTER"
echo "****************************************************************************************************"
CLUSTER_NAME="total.leila.sieben.fr"
LOG_FILE="log-dns.txt"

cleanup
kops create cluster --cloud=scaleway --zones=pl-waw-1 --name=$CLUSTER_NAME --networking=cilium \
  --cloud-labels="containerized=true" --yes >$LOG_FILE
validate
cleanup

printf "\n\n"
echo "****************************************************************************************************"
echo "                                    TESTING NONE DNS CLUSTER"
echo "****************************************************************************************************"
CLUSTER_NAME="total.nonedns"
LOG_FILE="log-nonedns.txt"

cleanup
kops create cluster --cloud=scaleway --zones=pl-waw-1 --name=$CLUSTER_NAME --networking=cilium --dns=none \
  --cloud-labels="containerized=true" --yes >$LOG_FILE
validate
cleanup
