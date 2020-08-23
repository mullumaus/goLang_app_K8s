#!/bin/sh

#
# script to deploy the GO application on Kubernetes
# 

NAMESPACE=technical-test
NODEIP=`kubectl describe node |grep InternalIP |cut -d ':' -f 2 | sed -e 's/ //'`
NODEPORT=30008
PV=log-volume
#switch default namespace to technical-test
#kubectl config set-context --current --namespace=${NAMESPACE}

function usage()
{
    echo "Use this script to deploy go application on Kubernetes"
    echo ""
    echo "./run.sh"
    echo "\t-h --help:   print this usage"
    echo "\t-d --deploy: deploy the application on Kubernetes"
    echo "\t-l --list:   list all resource in the namespace"
    echo "\t-t --test:   test the deployment"
    echo "\t-c --clean:  delete all resources in the namespace"
    echo ""
}

function deploy_application()
{
    kubectl create namespace  ${NAMESPACE}
	kubectl create -f pv.yaml
	kubectl create -f pvc.yaml
	kubectl create -f deployment.yaml
	kubectl create -f service.yaml
}

function test_deployment()
{
    curl ${NODEIP}:${NODEPORT}/version
}

function delete_deployment()
{
    kubectl delete namespace ${NAMESPACE}
	#persistent volume is not scoped to any namespace
	kubectl delete pv ${PV} 
}

function list_resource()
{
    kubectl get all --namespace=${NAMESPACE}
}

#main 
if [ "$#" -ne 1 ]; then
    usage
    exit
fi

if [ "$1" != "" ]; then
    PARAM=`echo $1 | awk -F= '{print $1}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        -d | --deploy)
            deploy_application
            ;;
        -l | --list)
            list_resource
            ;;
        -t | --test)
            test_deployment
            ;;
        -c | --clean)
            delete_deployment
            ;;                        
        *)
            echo "ERROR: unknown parameter $PARAM"
            usage
            exit 1
            ;;
    esac
    shift
fi
