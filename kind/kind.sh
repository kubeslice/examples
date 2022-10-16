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
KUBESLICE_CLI="kubeslice-cli"

ENV=kind.env
CLEAN=false
VERBOSE=false
CLI_CFG=${BASE_DIR}/config/topology.yaml
CLI_CFG_PASSED=false

# First, check args
VALID_ARGS=$(getopt -o chvek: --long clean,help,verbose,env,config: -- "$@")
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
    -k | --config)
        CLI_CFG=$2
	CLI_CFG_PASSED=true
        shift 2
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

# See if we're being asked to be chatty
if [ "$VERBOSE" == true ]; then
    # Log all the commands (w/o having to echo them)
    set -o xtrace
fi

# Check for requirements
echo Checking for required tools...
ERR=0
which ansible > /dev/null
if [ $? -ne 0 ]; then 
    echo Error: Ansible is required and was not found
    echo Downloading....
    sudo apt install -y ansible
fi 
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
    read -p "Do you want to proceed with downloading the prerequisite?(Y/n) " yn
    case $yn in
        [Yy] ) ansible-playbook -i ./../ansible/hosts ./../ansible/main.yaml;;
        [Nn] ) echo Exiting due to missing required tools; 
            exit 0;;
        * ) echo invalid response;
		    exit 1 ;;
    esac
else
    echo Requirement checking passed
fi

if id -nGz "$USER" | grep -qzxF "docker"; then 
    echo User $USER belongs to group docker
else 
    # echo User $USER doesnot belong to group "docker"
    # exit 0

    sudo usermod -aG docker $USER
    newgrp docker 
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

command -v $KUBESLICE_CLI
if ! $(command -v $KUBESLICE_CLI &> /dev/null) ; then
  echo "$KUBESLICE_CLI not found. Trying to download latest version"

fi

if ! $(command -v $KUBESLICE_CLI &> /dev/null) ; then
  echo "$KUBESLICE_CLI not found. Trying to download latest version"

  RELEASE_BASE_URL="https://github.com/kubeslice/kubeslice-cli/releases/download/0.3.0"
  
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CLI_URL="${RELEASE_BASE_URL}/kubeslice-cli-linux-amd64"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ $(uname -m) == 'arm64' ]]; then
      CLI_URL="${RELEASE_BASE_URL}/kubeslice-cli-darwin-arm64"
    elif [[ $(uname -m) == 'x86_64' ]]; then
      CLI_URL="${RELEASE_BASE_URL}/kubeslice-cli-darwin-amd64"
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

if [ "$CLI_CFG_PASSED" == false ]; then
    # Modify and use the default template topology file
    sed "s#<KUBECONFIG_PATH>#${BASE_DIR}/config/kubeconfig#g" ${BASE_DIR}/config/topology.yaml > ${PWD}/config/topology.tmp.yaml
    CLI_CFG=${PWD}/config/topology.tmp.yaml
fi

# Now CLI_CFG points at the correct file (default or user specified)
PROJECT_NAME=`grep project_name: $CLI_CFG | awk '{ print $2 }'`

######################################################################
# Create the kind clusters here
######################################################################

echo Create the Controller cluster
kind create cluster --name $CONTROLLER --config controller-cluster.yaml --wait 5m $KIND_K8S_VERSION
if [ $? -ne 0 ]; then
    echo "Kind cluster create failed... exiting"
    exit 1
fi

echo "Installing calico for cluster $CONTROLLER"
calico

echo Create the Worker clusters
for CLUSTER in ${WORKERS[@]}; do
    echo Creating cluster $CLUSTER    
    echo kind create cluster --name $CLUSTER --config worker-cluster.yaml $KIND_K8S_VERSION
    kind create cluster --name $CLUSTER --config worker-cluster.yaml --wait 5m $KIND_K8S_VERSION
    if [ $? -ne 0 ]; then
	echo "Kind cluster create failed... exiting"
	exit 1
    fi
    # Make sure the cluster context exists
    kubectl cluster-info --context $PREFIX$CLUSTER

    echo "Installing calico for cluster $CLUSTER"
    calico
done

echo
echo "*** Finished creating kind clusters... Starting KubeSlice Install ***"

######################################################################
# Add kubeslice config to the just-created kind clusters
######################################################################
# This sometimes fails (?) if the underlying kind clusters are busy...
# so consider a few retries
for i in 1 2 3; do
    $KUBESLICE_CLI --config $CLI_CFG install && break
    echo "$KUBESLICE_CLI returned an error... retrying"
done


######################################################################
# Start iperf installation
# 1. Add iperf namespaces to the clusters
# 2. Create a slice and onboard the iperf namespace in each cluster onto the slice
# 3. Deploy the iperf server and client
# 4. Wait for the DNS service name to be propogated to the client cluster
# 5. Verify connectivity between the clusters by running iperf
######################################################################
echo
echo "*** KubeSlice control plane installed... Starting iperf slice install ***"
# 1. Make namesapces first
echo "Creating namespaces in each cluster for iperf slice"
for WORKER in ${WORKERS[@]}; do
    kubectx $PREFIX$WORKER
    kubectl create namespace iperf
    sleep 10
done

# 2. Add the iperf slice
echo "Adding the iperf slice"
for i in 1 2 3; do
    $KUBESLICE_CLI --config $CLI_CFG create sliceConfig -n kubeslice-$PROJECT_NAME -f ${PWD}/config/slice-iperf.yaml && break
    echo "$KUBESLICE_CLI returned an error... retrying"
done

### Make sure the slice is ready before proceeding
echo "Wait for the slice to be ready"
for i in $(seq 1 20)
do
    sleep 10
    # Watch for the slice tunnel to be up
    STATUS=`kubectl get pods -n kubeslice-system | grep ^iperf-slice`
    [[ ! -z "$STATUS" ]] && echo $STATUS || echo -n "."
    STATUS=`echo $STATUS | awk '{ print $3 }'`
    if [[ "$STATUS" == "Running" ]]; then
	break
    fi 
    if [[ "$STATUS" =~ "ImagePullBackOff" ]]; then
	echo "***** Error: Docker pull limit exceeded.   Exiting"
	exit 1
    fi 
done
#kubectl get pods -n kubeslice-system
# Not sure why this sleep is necessary... but sometimes seems to be?
sleep 20
#kubectl get pods -n kubeslice-system

#############################################################
# 3. Iperf setup in the clusters/namespace/slice already created previously
# Switch to kind-worker-2 context
kubectx $PREFIX${WORKERS[1]}
kubectl apply -f iperf-server.yaml -n iperf
if [ $? -ne 0 ]; then
    echo "Apply failed... maybe kind cluster is busy?  Retry shortly"
    sleep 60
    kubectl apply -f iperf-server.yaml -n iperf
fi

echo "Wait for iperf to be Running"
for i in $(seq 1 20)
do
    sleep 10
    STATUS=`kubectl get pods -n iperf | egrep iperf-server`
    [[ ! -z "$STATUS" ]] && echo $STATUS || echo -n "."
    STATUS=`echo $STATUS | awk '{ print $3 }'`
    if [[ "$STATUS" == "Running" ]]; then
	break
    fi 
    if [[ "$STATUS" =~ "ImagePullBackOff" ]]; then
	echo "***** Error: Docker pull limit exceeded.   Exiting"
	exit 1
    fi 
done

# Switch to kind-worker-1 context
kubectx $PREFIX${WORKERS[0]}
kubectl apply -f iperf-sleep.yaml -n iperf
if [ $? -ne 0 ]; then
    echo "Apply failed... maybe kind cluster is busy?  Retry shortly"
    sleep 60
    kubectl apply -f iperf-sleep.yaml -n iperf
fi
echo "Wait for iperf to be Running"
for i in $(seq 1 20)
do
    sleep 10
    STATUS=`kubectl get pods -n iperf | egrep iperf-sleep`
    echo $STATUS
    STATUS=`echo $STATUS | awk '{ print $3 }'`
    if [[ "$STATUS" == "Running" ]]; then
	break
    fi 
    if [[ "$STATUS" =~ "ImagePullBackOff" ]]; then
	echo "***** Error: Docker pull limit exceeded.   Exiting"
	exit 1
    fi 
done

#############################################################
# 4. Wait for the service to be exported and the DNS name to be resolvable in the client cluster
echo "Waiting for iperf-server service reachable"
for i in $(seq 1 20)
do
    sleep 10
    STATUS=`kubectl describe serviceimport -n iperf | egrep "Dns Name:"`
    if [[ -z "$STATUS" ]]; then
	break
    fi
    echo -n "."
done

#############################################################
# 5. Check Iperf connectity from iperf sleep to iperf server
IPERF_CLIENT_POD=`kubectl get pods -n iperf | grep iperf-sleep | awk '{ print$1 }'`
kubectl exec -it $IPERF_CLIENT_POD -c iperf -n iperf -- iperf -c iperf-server.iperf.svc.slice.local -p 5201 -i 1 -b 10Mb;
if [ $? -ne 0 ]; then
  echo '***Error: Connectivity between clusters not succesful!'
  ERR=$((ERR+1))
fi

# set KUBECONFIG to previous value
export KUBECONFIG="${OLD_KUBECONFIG}"

# Return status
exit $ERR
