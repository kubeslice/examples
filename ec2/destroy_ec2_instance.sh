#!/usr/bin/env bash

KEY_PAIR="kubeslice-ec2"

BASE_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd ${BASE_DIR}/terraform

if [ -f "./tfplan" ]; then 
  terraform apply -destroy -auto-approve
  aws ec2 delete-key-pair --key-name ${KEY_PAIR}
  rm -rf ${BASE_DIR}/ssh_key
else 
  echo "No terraform plan file found! Exiting" 
  exit 1 
fi