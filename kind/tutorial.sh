#!/bin/bash
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

ENV=kind.env
WIDTH=`tput cols`
FAST=false
source $ENV

show () {
     echo $1 | fold -w $WIDTH -s
     echo
}

key () {
    if [ "$FAST" == false ]; then
        read -n 1 -p "Press any key to continue"
    	clear
    fi
}

# First, check args
VALID_ARGS=$(getopt -o fh --long fast,help -- "$@")
if [[ $? -ne 0 ]]; then
    exit 1;
fi
eval set -- "$VALID_ARGS"
while [ : ]; do
  case "$1" in
    -f | --fast)
        FAST=true
        shift
        ;;
    -h | --help)
	echo "Usage is:"
	echo "    bash tutorial.sh [<options>]"
	echo " "
	echo "    -f: fast - don't wait for keypress"
	echo "    -h | --help: Print this message"
        shift
	exit 0
        ;;
    --) shift; 
        break 
        ;;
  esac
done




clear
show "Welcome to the KubeSlice -kind- tutorial."

show "This script will walk you through KubeSlice as configured by the kind.sh script in this repository.  It will explain the key elements of KubeSlice and how they interact with applications under Kubernetes."

key

WORKER=${WORKERS[@]}

show "First, let's review the clusters that were created for you.   You have a KubeSlice 'controller' cluster named $CONTROLLER and several KubeSlice 'worker' clusters named $WORKER.   Using the tool kubectx, we'll switch through each of them and review what is inside each cluster."

(set -x; kubectx)

key

show "Let's go to the controller context..."
(set -x; kubectx $PREFIX$CONTROLLER)

show "The controller has nodes..."
(set -x; kubectl get nodes -o wide)
echo

show "The controller has several namespaces..."
(set -x; kubectl get ns)
echo

show "And the kubeslice-controller namespace on the controller contains the following pods..."
(set -x; kubectl get pods -n kubeslice-controller -o wide)
echo

show "The kubeslice-controller-manager pod oversees connectivity between clusters as well as slice management within a given cluster.   In this case, we have a cluster dedicated to the controller function... but could have also installed the controller inside a worker cluster as well."
key


show "Note that in addition to the kubeslice-controller namespace, we also have kubeslice-avesha.   kubeslice-avesha is a 'project' namespace.  The install script specified a project named 'avesha' and 'kubeslice-' was prepended to it as part of project creation.    Projects are a form of multi-tenancy and are one way kubeslice controller segments user state among the clusters it manages.  In this case, it is providing cluster-level segmentation.   I.e., no one cluster can be a member of multiple projects.  A kubeslice-controller can manage many projects.  "

show "We can inspect a controller and see the projects it is managing..."
(set -x; kubectl get projects -n kubeslice-controller)
echo

show "...and can inspect a project to see the clusters that have been registered to it."
(set -x; kubectl get clusters -n kubeslice-avesha)
echo

show "We can check for the presence of any slices in this project with..."
(set -x; kubectl get sliceconfigs -n kubeslice-avesha)
echo
show "And extensive details of the slice can be seen with..."
key
(set -x; kubectl describe sliceconfigs -n kubeslice-avesha)
key

show "Now, let's look at the worker clusters that were created.   We'll start with kind-worker-2."
(set -x; kubectx kind-worker-2)
echo

show "The worker has nodes..."
(set -x; kubectl get nodes -o wide)
echo

show "...and namespaces..."
(set -x; kubectl get ns)
echo

show "The kubeslice-system namespace holds the kubeslice infrastructure with the following pods"
(set -x; kubectl get pods -n kubeslice-system -o wide)

key

show "We can check for slices present in this cluster by doing:"
(set -x; kubectl  get slice -n kubeslice-system)

show "And we can look for details of the slice and the applications associated with it by:"
(set -x; kubectl describe slice -n kubeslice-system )
key

show "Although a more readable/filtered output (depending on what you want to see) may be seen with:"

(set -x; kubectl describe slice -n kubeslice-system | egrep 'Pod Ip:|Nsm Ip:|Pod Name:|Cluster Name:|Attached|Slice Subnet:|^Name:|Namespace')

show "In this case, we see we have slice 'convoy' and there is 1 namespace 'iperf' that has been added to it.   That namespace has one application 'iperf-server' on it.   We see the pod's CNI IP address as well as the address of the iperf server application on the NSM 'overlay' network."

show "It is the 'overlay' network that spans clusters and provides a way for applications in different clusters to interact as if they are on the same network.  Note that the 'Slice Subnet' contains the NSM address inside it."

key

show "Now let's check out the other worker cluster."
(set -x; kubectx kind-worker-1)
echo

show "This cluster also contains an application on the same slice."
(set -x; kubectl describe slice -n kubeslice-system | egrep 'Pod Ip:|Nsm Ip:|Pod Name:|Cluster Name:|Attached|Slice Subnet:|^Name:|Namespace')
echo

show "In this case we have an iperf client (iperf-sleep) as part of the iperf namespace.  Note that it's address is also within the 'Slice Subnet' just like the iperf server in the other cluster.   Also note that there is not iperf server inthe local cluster."

show "However, iperf server in the remote cluster has exported it's reachability information.   It can be seen with:"

(set -x; kubectl get serviceimport -n iperf)
(set -x; kubectl describe serviceimport -n iperf | egrep 'Dns Name|Ip:')
DNSNAME=`kubectl describe serviceimport -n iperf | egrep -m1 'Dns Name' | awk '{ print $3 }'`
echo
key

show "Now we can demonstrate inter-cluster connectivity by asking the iperf client to talk to the iperf server across the slice using the imported service name."
IPERF_CLIENT_POD=`kubectl get pods -n iperf | grep iperf-sleep | awk '{ print$1 }'`
(set -x; kubectl exec -it $IPERF_CLIENT_POD -c iperf -n iperf -- iperf -c $DNSNAME -p 5201 -i 1 -b 10Mb)
echo

show "This shows that iperf is able to talk client to server.   And to briefly look at the network hops, we can do a traceroute to see the flow."

(set -x; kubectl exec -it $IPERF_CLIENT_POD -n iperf -c sidecar -- /bin/bash -c "traceroute -n $DNSNAME")
echo

show "From this we see the address of the iperf client sends to the NSM router on it's local subnet/cluster.   That router forwards to the inter-cluster link that connects the two clusters together.  The frame then arrives at the far side NSM router which forwards it on to the iperf-server in the remote cluster."

exit 0


