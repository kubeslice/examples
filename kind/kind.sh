#!/usr/bin/env bash
#
# 	Copyright (c) 2022 Avesha, Inc. All rights reserved. # # SPDX-License-Identifier: Apache-2.0
#
# 	Licensed under the Apache License, Version 2.0 (the "License");
# 	you may not use this file except in compliance with the License.
# 	You may obtain a copy of the License at
#
# 	http://www.apache.org/licenses/LICENSE-2.0
#
#	Unless required by applicable law or agreed to in writing, software
#	distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#	See the License for the specific language governing permissions and
#	limitations under the License.

BASE_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
KUBESLICE_CLI="slicectl"

ENV=kind.env
CLEAN=false
VERBOSE=false

# First, check args
VALID_ARGS=$(getopt -o chve: --long clean,help,verbose,env: -- "$@")
if [[ $? -ne 0 ]]; then
    exit 1;
fi
eval set -- "$VALID_ARGS"
while [ : ]; do
  case "$1" in
    -e | --env)
        echo "Passed environment file is: '$2'"
	ENV=$2
        shift 2
        ;;
    -c | --clean)
        CLEAN=true
        shift
        ;;
    -h | --help)
	echo "Usage is:"
	echo "    bash kind.sh [<options>]"
	echo " "
	echo "    -c | --clean: delete all clusters"
	echo "    -e | --env <environment file>: Specify custom environment details"
	echo "    -h | --help: Print this message"
        shift
	exit 0
        ;;
    -v | --verbose)
        VERBOSE=true
        shift
        ;;
    --) shift; 
        break 
        ;;
  esac
done

# Pull in the specified environemnt
source $ENV

# Setup kind multicluster with KubeSlice
CONTROLLER_TEMPLATE="controller.template.yaml"
WORKER_TEMPLATE="worker.template.yaml"
SLICE_TEMPLATE="slice.template.yaml"
REGISTRATION_TEMPLATE="clusters-registration.template.yaml"

CLUSTERS=($CONTROLLER)
CLUSTERS+=(${WORKERS[*]})

clean() {
    echo Cleaning up all clusters
    for CLUSTER in ${CLUSTERS[@]}; do
        echo kind delete cluster --name $CLUSTER
        kind delete cluster --name $CLUSTER
    done

    # [ -d ${BASE_DIR}/bin ] && rm -rf ${BASE_DIR}/bin
    [ -d ${BASE_DIR}/config ] && rm -rf ${BASE_DIR}/config/kubeconfig
    
}

calico() {
  CLUSTER_DOCKER_IP=$(kubectl --kubeconfig config/kubeconfig get nodes -o wide | grep control-plane | awk '{  print $6}')
  CURRENT_CONTEXT=$(kubectl --kubeconfig config/kubeconfig config current-context)
  SERVER_CONFIG=$(grep -m 1 -B 2 "name: $CURRENT_CONTEXT" ./config/kubeconfig | grep server | sed -n 's#server: https://##p' | sed ':a;s/^\([[:space:]]*\)[[:space:]]/\1/;ta')
  sed -i "s,https://$SERVER_CONFIG,https://$CLUSTER_DOCKER_IP:6443,g" ${BASE_DIR}/config/kubeconfig

  kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.0/manifests/tigera-operator.yaml
#   echo "Waiting on calico to start..."
  sleep 5
  kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.0/manifests/custom-resources.yaml
  echo "Waiting on calico to start..."
  sleep 25
  for pod in $(kubectl get pods -n calico-system | tail -n +2 | awk '{ print $1 }'); do
    while [[ $(kubectl get pods $pod -n calico-system -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
      sleep 1
    done
  done
}

# Check for requirements
echo Checking for required tools...
ERR=0
which kind > /dev/null
if [ $? -ne 0 ]; then
    echo Error: kind is required and was not found
    ERR=$((ERR+1))
fi
which kubectl > /dev/null
if [ $? -ne 0 ]; then
    echo Error: kubectl is required and was not found
    ERR=$((ERR+1))
fi
which kubectx > /dev/null
if [ $? -ne 0 ]; then
    echo Error: kubectx is required and was not found
    ERR=$((ERR+1))
fi
which helm > /dev/null
if [ $? -ne 0 ]; then
    echo Error: helm is required and was not found
    ERR=$((ERR+1))
fi
which docker > /dev/null
if [ $? -ne 0 ]; then
    echo Error: docker is required and was not found
    ERR=$((ERR+1))
fi
OS=`awk -F= '/^ID=/{print $2}' /etc/os-release`
if [ "$OS" == "ubuntu" ]; then
    INOT_USER_WAT=`sysctl fs.inotify.max_user_watches | awk '{ print $3 }'`
    if [ $INOT_USER_WAT -lt 524288 ]; then
	echo Warning: kind recommends at least 524288 fs.inotify.max_user_watches
    fi
    INOT_USER_INST=`sysctl fs.inotify.max_user_instances | awk '{ print $3 }'`
    if [ $INOT_USER_INST -lt 512 ]; then
	echo Warning: kind recommends at least 512 fs.inotify.max_user_instances
    fi
else
    # Not Ubuntu... on your own
    echo Platform is $OS \(not Ubuntu\)... other checks skipped
fi

if [ $ERR -ne 0 ]; then
    echo Exiting due to missing required tools
    exit 0        # Done until all requirements are met
else
    echo Requirement checking passed
fi

# See if we're being asked to cleanup
if [ "$CLEAN" == true ]; then
    clean
    exit 0
fi

# Create kind clusters
if [ ! -z "$KUBECONFIG" ]; then
  OLD_KUBECONFIG="$KUBECONFIG"
fi

[ ! -d ${BASE_DIR}/config ] && mkdir ${BASE_DIR}/config

export KUBECONFIG=${BASE_DIR}/config/kubeconfig

echo Create the Controller cluster
echo kind create cluster --name $CONTROLLER --config controller-cluster.yaml $KIND_K8S_VERSION
kind create cluster --name $CONTROLLER --config controller-cluster.yaml $KIND_K8S_VERSION

echo "Installing calico for cluster $CONTROLLER"
calico

echo Create the Worker clusters
for CLUSTER in ${WORKERS[@]}; do
    echo Creating cluster $CLUSTER    
    echo kind create cluster --name $CLUSTER --config worker-cluster.yaml $KIND_K8S_VERSION
    kind create cluster --name $CLUSTER --config worker-cluster.yaml $KIND_K8S_VERSION
    # Make sure the cluster context exists
    kubectl cluster-info --context $PREFIX$CLUSTER

    echo "Installing calico for cluster $CLUSTER"
    calico
done

# See if we're being asked to be chatty
if [ "$VERBOSE" == true ]; then
    # Log all the commands (w/o having to echo them)
    set -o xtrace
fi

if [ ! $(command -v $KUBESLICE_CLI &> /dev/null) ]; then
  echo "$KUBESLICE_CLI not found. Trying to download latest version"
  
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CLI_URL="https://github.com/kubeslice/slicectl/releases/download/0.2.0-rc4-topology/slicectl-linux-amd64"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ $(uname -m) == 'arm64' ]]; then
      CLI_URL="https://github.com/kubeslice/slicectl/releases/download/0.2.0-rc4-topology/slicectl-darwin-arm64"
    elif [[ $(uname -m) == 'x86_64' ]]; then
      CLI_URL="https://github.com/kubeslice/slicectl/releases/download/0.2.0-rc4-topology/slicectl-darwin-amd64"
    fi
  fi

  [ ! -d ${BASE_DIR}/bin ] && mkdir ${BASE_DIR}/bin

  # wget -O $KUBESLICE_CLI $CLI_URL
  if [ ! -f "${BASE_DIR}/bin/$KUBESLICE_CLI" ]; then
    wget -O $KUBESLICE_CLI $CLI_URL 
    mv ${BASE_DIR}/$KUBESLICE_CLI ${BASE_DIR}/bin/    
  fi
  
  chmod +x ${BASE_DIR}/bin/$KUBESLICE_CLI
  # echo Adding $KUBESLICE_CLI to PATH
  # export PATH=$PATH:${BASE_DIR}/bin/$KUBESLICE_CLI

  KUBESLICE_CLI=${BASE_DIR}/bin/$KUBESLICE_CLI
fi

sed -i "s#<KUBECONFIG_PATH>#${BASE_DIR}/config/kubeconfig#g" ${BASE_DIR}/config/topology.yaml 

$KUBESLICE_CLI --config ${BASE_DIR}/config/topology.yaml install

# # Iperf setup
# echo Setup Iperf
# # Switch to kind-worker-1 context
# kubectx $PREFIX${WORKERS[0]}
# kubectx

# kubectl apply -f iperf-sleep.yaml -n iperf
# echo "Wait for iperf to be Running"
# sleep 60
# kubectl get pods -n iperf

# # Switch to kind-worker-2 context
# for WORKER in ${WORKERS[@]}; do
#     if [[ $WORKER -ne ${WORKERS[0]} ]]; then 
#         kubectx $PREFIX$WORKER
#         kubectx
#         kubectl apply -f iperf-server.yaml -n iperf
#         echo "Wait for iperf to be Running"
#         sleep 60
#         kubectl get pods -n iperf
#     fi
# done

# # Switch to worker context
# kubectx $PREFIX${WORKERS[0]}
# kubectx

# sleep 90
# # Check Iperf connectity from iperf sleep to iperf server
# IPERF_CLIENT_POD=`kubectl get pods -n iperf | grep iperf-sleep | awk '{ print$1 }'`

# kubectl exec -it $IPERF_CLIENT_POD -c iperf -n iperf -- iperf -c iperf-server.iperf.svc.slice.local -p 5201 -i 1 -b 10Mb;
# if [ $? -ne 0 ]; then
#     echo '***Error: Connectivity between clusters not succesful!'
#     ERR=$((ERR+1))
# fi

# # set KUBECONFIG to previous value
# export KUBECONFIG="${OLD_KUBECONFIG}"

# # Return status
# exit $ERR

exit 0