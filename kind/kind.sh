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
CONFIG_DIR=${BASE_DIR}/config

# ENV=kind.env
CLEAN=false
VERBOSE=false
BINARY_NAME="slicectl"
TOPOLOGY_FILE=""
PATH_CONFIG_FILE=/tmp/kind-

source ~/.bash_profile

cleanup() {
#   $(${BINARY_NAME} uninstall)
  [[ -z "$1" ]] && slicectl --config=$1 uninstall; exit 0

  slicectl --config=${PWD}/config/kind-demo.sh uninstall
  # slicectl uninstall
}

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  VALID_ARGS=$(getopt -o chvf: --long clean,help,verbose,file: -- "$@")
  if [[ $? -ne 0 ]]; then
      exit 1;
  fi
  eval set -- "$VALID_ARGS"
  echo "OS = Linux"
#   BINARY_NAME="slicectl-darwin-amd64"
  while [ : ]; do
    case "$1" in
    #   -e | --env)
    #       echo "Passed environment file is: '$2'"
  	#     ENV=$2
    #       shift 2
    #       ;;
      -c | --clean)
          cleanup $TOPOLOGY_FILE
          shift
          ;;
      -f | --file)
          TOPOLOGY_FILE="$OPTARG"
          echo $TOPOLOGY_FILE > /tmp/kind-config-file
          shift 2
          ;;
      -h | --help)
  	echo "Usage is:"
  	echo "    bash kind.sh [<options>]"
  	echo " "
  	echo "    -c | --clean: delete all clusters"
  	# echo "    -e | --env <environment file>: Specify custom environment details"
    echo "    -f | --file <path_to_file> : [Optional] Path to topology file. See https://github.com/kubeslice/slicectl/blob/master/samples/template.yaml and https://github.com/kubeslice/slicectl/blob/master/samples/kind-demo.yaml"
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
elif [[ "$OSTYPE" == "darwin"* ]]; then
  echo "OS = MacOS"
#   if [[ $(uname -m) == "arm64" ]]; then
#     # BINARY_NAME="slicectl-darwin-arm64"
#   elif [[ $(uname -m) == "x86_64" ]]; then
#     # BINARY_NAME="slicectl-darwin-amd64"
#   else
#     echo "Unknown arch... exiting"
#     exit 1
#   fi

  OPTS=$(getopt chf: $*)
  if [ $? != 0 ]; then echo "Failed parsing options" ; exit 1 ; fi
  echo "Options: $OPTS"
  eval set -- "$OPTS"
  while true; do
    case $1 in
      -c ) cleanup ; exit 0 ;;
      -f ) TOPOLOGY_FILE="$2" ; echo $TOPOLOGY_FILE > /tmp/kind-config-file; shift 2 ;;
      -h )
  	echo "Usage is:"
  	echo "    bash kind.sh [<options>]"
  	echo " "
  	echo "    -c | --clean: delete all clusters"
  	# echo "    -e | --env <environment file>: Specify custom environment details"
    echo "    -f | --file <path_to_file> : [Optional] Path to topology file. See https://github.com/kubeslice/slicectl/blob/master/samples/template.yaml and https://github.com/kubeslice/slicectl/blob/master/samples/kind-demo.yaml"
  	echo "    -h | --help: Print this message"
    shift
  	exit 0
          ;;
      -- ) shift ; break ;;
      * ) break ;;
    esac
  done
else
  echo "Unknow OS... exiting"
  exit -2
fi

# Pull in the specified environemnt
# source $ENV

# Check for requirements
echo "Checking for required tools..."
if [ ! $(command -v ${BINARY_NAME}) ]; then
  echo "Required tool ${BINARY_NAME} not found in PATH"
  echo "Please get it from https://github.com/kubeslice/slicectl/releases"
  exit 126
fi

if [ -z "$TOPOLOGY_FILE" ]; then
  echo "Config file $TOPOLOGY_FILE not found"
  echo "Running ${BINARY_NAME} using default topology file"

  TOPOLOGY_FILE=${CONFIG_DIR}/kind-demo.yaml
  
  [[ -f "$TOPOLOGY_FILE" ]] && ${BINARY_NAME} --config=$TOPOLOGY_FILE install
else
  echo "Running ${BINARY_NAME} with topology file $TOPOLOGY_FILE"
  
  ${BINARY_NAME} --config=$TOPOLOGY_FILE install
fi

echo "Done"
exit 0