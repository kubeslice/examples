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

ENV=kind.env
CLEAN=false
VERBOSE=false
BINARY_NAME="slicectl"
TOPOLOGY_FILE=""

cleanup() {
#   $(${BINARY_NAME} uninstall)
  slicectl uninstall
}

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  VALID_ARGS=$(getopt -o chvef: --long clean,help,verbose,env,file: -- "$@")
  if [[ $? -ne 0 ]]; then
      exit 1;
  fi
  eval set -- "$VALID_ARGS"
  echo "OS = Linux"
#   BINARY_NAME="slicectl-darwin-amd64"
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
      -f | --file)
          TOPOLOGY_FILE="$OPTARG"
          shift 2
          ;;
      -h | --help)
  	echo "Usage is:"
  	echo "    bash kind.sh [<options>]"
  	echo " "
  	echo "    -c | --clean: delete all clusters"
  	echo "    -e | --env <environment file>: Specify custom environment details"
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
      -f ) TOPOLOGY_FILE="$2" ; shift 2 ;;
      -h )
  	echo "Usage is:"
  	echo "    bash kind.sh [<options>]"
  	echo " "
  	echo "    -c | --clean: delete all clusters"
  	echo "    -e | --env <environment file>: Specify custom environment details"
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
source $ENV

# Check for requirements
echo "Checking for required tools..."
if [ ! $(command -v ${BINARY_NAME}) ]; then
  echo "Required tool ${BINARY_NAME} not found in PATH"
  echo "Please get it from https://github.com/kubeslice/slicectl/releases"
  exit 126
fi

if [ -z "$TOPOLOGY_FILE" ]; then
  echo "Config file $TOPOLOGY_FILE not found"
  echo "Running ${BINARY_NAME} without topology file"
  echo "Trying to run binary file $BINARY_NAME"
  $(${BINARY_NAME} --profile=full-demo install)
else
  echo "Running ${BINARY_NAME} with topology file $TOPOLOGY_FILE"
  echo "Trying to run binary file $BINARY_NAME"
  $(${BINARY_NAME} --config=$TOPOLOGY_FILE install)
fi

echo "Done"
exit 0