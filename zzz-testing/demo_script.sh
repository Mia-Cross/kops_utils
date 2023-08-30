<<<<<<<<<<<< SHORT VERSION

go run ./cmd/kops/ create cluster --name cluster.k8s.local --cloud scaleway --zones=fr-par-1 --networking cilium --yes

go run ./cmd/kops validate cluster cluster.k8s.local --wait=10m
## SHOW ALL PODS RUNNING ON MASTER

go run ./cmd/kops edit instancegroup nodes-fr-par-1
go run ./cmd/kops update cluster --yes

cd zzz-testing
kubectl create secret docker-registry registry-secret --docker-server=rg.fr-par.scw.cloud --docker-username=bidouille --docker-password=$SCW_SECRET_KEY
kubectl apply -f cowsay-deployment.yaml
kubectl get all
kubectl apply -f whoami-deployment.yaml
## SHOW ALL PODS RUNNING ON NODE
## SHOW WHOAMI --> localhost:8000
## SHOW THE COW --> localhost:8080

## SHOW NEW INSTANCES IN CONSOLE
go run ./cmd/kops validate cluster cluster.k8s.local --wait=10m

go run ./cmd/kops delete cluster --name=cluster.k8s.local --yes




\\\\\\ ORIGINAL ///////////////////

go run ./cmd/kops/ create cluster --name cluster.k8s.local --cloud scaleway --zones=fr-par-1 --networking cilium --yes
## SHOW NODEUP LOG
## SHOW PROTOKUBE LOG
## SHOW ETCD-MANAGER LOG
## SHOW ALL PODS RUNNING ON MASTER
go run ./cmd/kops validate cluster cluster.k8s.local --wait=10m
cd zzz-testing
kubectl create secret docker-registry registry-secret --docker-server=rg.fr-par.scw.cloud --docker-username=bidouille --docker-password=$SCW_SECRET_KEY
kubectl apply -f cowsay-deployment.yaml
kubectl get all
kubectl apply -f whoami-deployment.yaml
## SHOW ALL PODS RUNNING ON NODE
## SHOW WHOAMI --> localhost:8000
## SHOW THE COW --> localhost:8080
go run ./cmd/kops replace -f zzz-dev-scripts/cluster.k8s.local-extra_masters.yaml
go run ./cmd/kops create instancegroup --name=cluster.k8s.local control-plane2 --role=master --subnet=fr-par-1  --edit=true
go run ./cmd/kops create instancegroup --name=cluster.k8s.local control-plane3  --role=master --subnet=fr-par-1  --edit=false
go run ./cmd/kops update cluster --yes
go run ./cmd/kops edit instancegroup nodes-fr-par-1
go run ./cmd/kops update cluster --yes
## SHOW NEW INSTANCES IN CONSOLE
go run ./cmd/kops export kubeconfig
## SHOW ETCD LOG
## SHOW KOPS-CONTROLLER LOG
go run ./cmd/kops edit instancegroup nodes-fr-par-1
go run ./cmd/kops update cluster --yes
## SHOW THE COW --> localhost:8080
## SHOW WHOAMI --> localhost:8000
go run ./cmd/kops delete cluster --name=cluster.k8s.local --yes




node_controller.go:401] Initializing node control-plane-fr-par-1-0 with cloud provider
shared_informer.go:262] Caches are synced for service
node_controller.go:215] error syncing 'control-plane-fr-par-1-0': failed to get instance metadata for node control-plane-fr-par-1-0: scaleway-sdk-go: http error 501 Not Implemented: unknown service, requeuing
node_controller.go:401] Initializing node nodes-fr-par-1-0 with cloud provider
node_controller.go:244] Error getting   instance metadata for node addresses: scaleway-sdk-go: http error 501 Not Implemented: unknown service

Initializing node control-plane-fr-par-1 with cloud provider
shared_informer.go:262] Caches are synced for service
node_controller.go:465] Successfully initialized node control-plane-fr-par-1 with cloud provider


kubernetes/pkg/controller/cloud/node_controller.go
