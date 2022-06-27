#!/usr/bin/env bash

BASE_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_DIR=${BASE_DIR}/kubernetes-manifests
ENV_FILE=${BASE_DIR}/../kind.env

if [[ ! -f $ENV_FILE ]]; then
  echo "${ENV_FILE} file not found! Exiting"
  exit 1
fi

source $ENV_FILE

PRODUCT_CLUSTER="${PREFIX}${WORKERS[0]}"
SERVICES_CLUSTER="${PREFIX}${WORKERS[1]}"
BOUTIQUE_NAMESPACE=boutique

uninstall() {
    echo "Delete boutique application in both clusters"
    kubectx $SERVICES_CLUSTER
    kubectl delete -f ${CONFIG_DIR}/paymentservice.yaml -n $BOUTIQUE_NAMESPACE
    kubectl delete -f ${CONFIG_DIR}/redis.yaml -n $BOUTIQUE_NAMESPACE
    kubectl delete -f ${CONFIG_DIR}/adservice.yaml -n $BOUTIQUE_NAMESPACE
    kubectl delete -f ${CONFIG_DIR}/cartservice.yaml -n $BOUTIQUE_NAMESPACE
    kubectl delete -f ${CONFIG_DIR}/emailservice.yaml -n $BOUTIQUE_NAMESPACE
    kubectl delete -f ${CONFIG_DIR}/checkoutservice.yaml -n $BOUTIQUE_NAMESPACE
    kubectl delete -f ${CONFIG_DIR}/recommendationservice.yaml -n $BOUTIQUE_NAMESPACE
    kubectl delete -f ${CONFIG_DIR}/currencyservice.yaml -n $BOUTIQUE_NAMESPACE
    kubectl delete -f ${CONFIG_DIR}/productcatalogservice.yaml -n $BOUTIQUE_NAMESPACE
    kubectl delete -f ${CONFIG_DIR}/shippingservice.yaml -n $BOUTIQUE_NAMESPACE

    kubectx $PRODUCT_CLUSTER
    kubectl delete -f ${CONFIG_DIR}/frontend.yaml -n $BOUTIQUE_NAMESPACE
    kubectl delete -f ${CONFIG_DIR}/loadgenerator.yaml -n $BOUTIQUE_NAMESPACE

    kubectx $PREFIX$CONTROLLER
    kubectl apply -f deletewater.yaml -n kubeslice-avesha
    echo "Wait for boutique namespace to be deboarded"
    sleep 30
    kubectl delete -f deletewater.yaml -n kubeslice-avesha
    for cluster in $SERVICES_CLUSTER $PRODUCT_CLUSTER; do
      echo "Deleting namespace $BOUTIQUE_NAMESPACE on cluster $cluster"
      kubectx $cluster
      [[ $(kubectl get namespaces | grep $BOUTIQUE_NAMESPACE) ]] && kubectl delete namespace $BOUTIQUE_NAMESPACE
    done
}

help() {
    echo "Usage: boutique.sh [--delete]"
}

# Get the options
while getopts ":d:delete:help:" option; do
  case $option in
    d | delete) # Uninstall
      uninstall
      exit;;
    h |help)
      help
      exit;;
   esac
done

echo "Creating boutique namespace in both clusters then creating the slice in the controller"
kubectx $PRODUCT_CLUSTER
kubectl create namespace $BOUTIQUE_NAMESPACE
kubectx $SERVICES_CLUSTER
kubectl create namespace $BOUTIQUE_NAMESPACE
kubectx $PREFIX$CONTROLLER
kubectl apply -f water.yaml -n kubeslice-avesha
echo "Waiting a few seconds for slice to be applied"
sleep 10
kubectx $SERVICES_CLUSTER
kubectl apply -f ${CONFIG_DIR}/paymentservice.yaml -n $BOUTIQUE_NAMESPACE
kubectl apply -f ${CONFIG_DIR}/redis.yaml -n $BOUTIQUE_NAMESPACE
kubectl apply -f ${CONFIG_DIR}/adservice.yaml -n $BOUTIQUE_NAMESPACE
kubectl apply -f ${CONFIG_DIR}/cartservice.yaml -n $BOUTIQUE_NAMESPACE
kubectl apply -f ${CONFIG_DIR}/emailservice.yaml -n $BOUTIQUE_NAMESPACE
kubectl apply -f ${CONFIG_DIR}/checkoutservice.yaml -n $BOUTIQUE_NAMESPACE
kubectl apply -f ${CONFIG_DIR}/recommendationservice.yaml -n $BOUTIQUE_NAMESPACE
kubectl apply -f ${CONFIG_DIR}/currencyservice.yaml -n $BOUTIQUE_NAMESPACE
kubectl apply -f ${CONFIG_DIR}/productcatalogservice.yaml -n $BOUTIQUE_NAMESPACE
kubectl apply -f ${CONFIG_DIR}/shippingservice.yaml -n $BOUTIQUE_NAMESPACE

kubectx $PRODUCT_CLUSTER
kubectl apply -f ${CONFIG_DIR}/frontend.yaml -n $BOUTIQUE_NAMESPACE
kubectl apply -f ${CONFIG_DIR}/loadgenerator.yaml -n $BOUTIQUE_NAMESPACE

echo "Waiting for pods to run"
sleep 120
kubectl port-forward deployment/frontend 8080:8080 -n boutique
