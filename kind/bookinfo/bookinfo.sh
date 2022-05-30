#!/usr/bin/env bash

BASE_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_DIR=${BASE_DIR}/config_files

PRODUCT_CLUSTER="kind-worker-1"
SERVICES_CLUSTER="kind-worker-2"
BOOKINFO_NAMESPACE=bookinfo

kubectx $PRODUCT_CLUSTER
kubectl create namespace $BOOKINFO_NAMESPACE

function wait_for_pods {
  for pod in $(kubectl get pods -n $BOOKINFO_NAMESPACE | grep -v NAME | awk '{ print $1 }'); do
    counter=0

    while [[ $(kubectl get pods $pod -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}' -n $BOOKINFO_NAMESPACE) != True ]]; do
      sleep 1
      let counter=counter+1

      if ((counter == 120)); then
        echo "POD $pod failed to start in 120 seconds"
        echo "Exiting"

        exit -1
      fi
    done
  done
}

echo "Installing productpage"
kubectl apply -f ${CONFIG_DIR}/productpage.yaml -n $BOOKINFO_NAMESPACE

echo "Waiting for pods to be ready"
wait_for_pods

echo "Productpage installed"
kubectl get pods -n $BOOKINFO_NAMESPACE

kubectx $SERVICES_CLUSTER
kubectl create namespace $BOOKINFO_NAMESPACE

kubectl apply -f ${CONFIG_DIR}/details.yaml -n $BOOKINFO_NAMESPACE
kubectl apply -f ${CONFIG_DIR}/ratings.yaml -n $BOOKINFO_NAMESPACE
kubectl apply -f ${CONFIG_DIR}/reviews.yaml -n $BOOKINFO_NAMESPACE

echo "Waiting for pods to be ready"
wait_for_pods

kubectl apply -f ${CONFIG_DIR}/serviceexports.yaml -n $BOOKINFO_NAMESPACE

# echo "Reviewing pods on namespaces bookinfo - $SERVICES_CLUSTER"

echo "Verifying serviceexport"
kubectl get serviceexport -n $BOOKINFO_NAMESPACE

echo "Verifying productpage"
kubectx $PRODUCT_CLUSTER
kubectl get serviceimport -n $BOOKINFO_NAMESPACE

echo "Printing services"
kubectl get services -n $BOOKINFO_NAMESPACE