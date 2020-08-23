IMAGE_NAME := goapp_image
NAMESPACE := technical-test
PV := log-volume
kubectl config set-context --current --namespace=$(NAMESPACE)
#eval $(minikube docker-env)  #to user local docker image
#Get node IP
NODEIP := $(shell kubectl describe node |grep InternalIP |cut -d ':' -f 2 | sed -e 's/ //')
NODEPORT := 30008

deploy:
	kubectl create namespace  $(NAMESPACE)
	kubectl create -f pv.yaml
	kubectl create -f pvc.yaml
	kubectl create -f deployment.yaml
	kubectl create -f service.yaml

list:
	kubectl get all --namespace=$(NAMESPACE)


listpod:
	kubectl get pod --namespace=$(NAMESPACE)

test:
	curl $(NODEIP):$(NODEPORT)/version

clean: 
	-kubectl delete namespace $(NAMESPACE)
	#persistent volume is not scoped to any namespace
	-kubectl delete pv $(PV) 
	