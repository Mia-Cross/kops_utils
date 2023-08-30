#!/usr/bin/zsh

export KOPS_STATE_STORE=scw://kops-state-store-testing

make kops
if [ $? != 0 ]; then
  echo "ERROR IN BUILD"
  exit 1
fi

kubetest2 kops \
  -v 10 \
  --up --down \
  --cloud-provider=scaleway \
  --cluster-name=e2e-scw.k8s.local \
  --create-args="--networking=cilium" \
  --kops-binary-path=.build/dist/linux/amd64/kops \
  --env KOPS_FEATURE_FLAGS=Scaleway \
  --env SCW_PROFILE=kops-testing \
  --env S3_REGION=fr-par \
  --env S3_ENDPOINT=https://s3.fr-par.scw.cloud \
  --env S3_ACCESS_KEY_ID=*********************** \
  --env S3_SECRET_ACCESS_KEY=************************************* \
  --env KOPS_BASE_URL="https://s3.fr-par.scw.cloud/kops-images/kops/1.27.0-alpha.1" \
  --env DNSCONTROLLER_IMAGE="rg.fr-par.scw.cloud/kops/dns-controller:1.27.0-alpha.1" \
  --env KOPSCONTROLLER_IMAGE="rg.fr-par.scw.cloud/kops/kops-controller:1.27.0-alpha.1" \
  --kubernetes-version=v1.25.5 \
  --test=kops \
  -- \
  --test-package-version=v1.27.0-alpha.1 \
  --parallel 25 \
  --skip-regex="\[Slow\]|\[Serial\]|\[Disruptive\]|\[Flaky\]|\[Feature:.+\]|\[HPA\]|Dashboard|RuntimeClass|RuntimeHandler"



.PHONY: test-e2e-scaleway-simple
test-e2e-scaleway-simple: test-e2e-install
	#kubetest2 kops -v=2 --cloud-provider=scaleway --cluster-name=e2e-test-scw.k8s.local --kops-binary-path=/kops/.build/dist/$(GOOS)/$(GOARCH)/kops \
# 		--build --kops-root=/kops --stage-location=${STAGE_LOCATION:-}
	kubetest2 kops -v=2 --cloud-provider=scaleway --cluster-name=e2e-test-scw.k8s.local --kops-binary-path=/kops/.build/dist/$(GOOS)/$(GOARCH)/kops \
    	-v 10 \
    	--up --down \
    	--state=scw://kops-state-store-testing \
    	--env S3_ENDPOINT=https://s3.fr-par.scw.cloud \
    	--env JOB_NAME=pull-kops-e2e-kubernetes-scw-kubetest2 \
    	--env SCW_CONFIG_PATH=/home/leila/.config/scw/config.yaml \
    	--env SCW_PROFILE=kops-testing \
    	--create-args "--networking=cilium --api-loadbalancer-type=public --node-count=2 --master-count=3" \
    	--kubernetes-version=https://storage.googleapis.com/kubernetes-release/release/stable-1.20.txt \
    	--test=kops \
    	-- \
    	--ginkgo-args="--debug" \
    	--test-package-marker=stable-1.20.txt \
    	--parallel 25 \
    	--skip-regex="\[Slow\]|\[Serial\]|\[Disruptive\]|\[Flaky\]|\[Feature:.+\]|\[HPA\]|Dashboard|RuntimeClass|RuntimeHandler|nfs|NFS|Services.*functioning.*NodePort|Services.*rejected.*endpoints|Services.*NodePort.*listening.*same.*port|TCP.CLOSE_WAIT|should.*run.*through.*the.*lifecycle.*of.*Pods.*and.*PodStatus" \
    	> logtest.txt
#    	--kops-version-marker=https://storage.googleapis.com/k8s-staging-kops/kops/releases/markers/release-1.20/latest-ci.txt \   #conflicts with kops-binary-path
