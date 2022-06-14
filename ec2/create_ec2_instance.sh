#!/usr/bin/env bash

BASE_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

REGION=$(aws configure list | grep region | awk '{  print $2}')
KEY_PAIR="kubeslice-ec2"
KEY_PAIR_FILE="${BASE_DIR}/ssh_key/${KEY_PAIR}.pem"

echo "File: "
echo $KEY_PAIR_FILE

if [[ ! -d ${BASE_DIR}/ssh_key ]]; then 
  mkdir -p ${BASE_DIR}/ssh_key; 
fi 

if [ ! -f ${KEY_PAIR_FILE} ]; then 
  echo "Creating new ssh key"
  aws ec2 create-key-pair --key-name ${KEY_PAIR} --query 'KeyMaterial' --output text > ${KEY_PAIR_FILE}
  chmod 0400 ${KEY_PAIR_FILE}
fi

if [[ $OSTYPE == "darwin"* ]]; then
  export IS_MAC="true"
fi
 
TERRAFORM_VAR_FILE=${BASE_DIR}/terraform/terraform.tfvars
TERRAFORM_VAR_TEMPLATE=${BASE_DIR}/terraform/templates/terraform.vars

cat ${TERRAFORM_VAR_TEMPLATE} > ${TERRAFORM_VAR_FILE}

if [ ! -z "${IS_MAC+x}" ]; then
  sed -i.backup "s/<REGION>/\"${REGION}\"/g" ${TERRAFORM_VAR_FILE}
  sed -i.backup "s/<KEY_PAIR>/\"${KEY_PAIR}\"/g" ${TERRAFORM_VAR_FILE}
  sed -i.backup "s#<KEY_PAIR_FILE>#\"${KEY_PAIR_FILE}\"#g" ${TERRAFORM_VAR_FILE}
else
  sed -i "s/<REGION>/\"${REGION}\"/g" ${TERRAFORM_VAR_FILE}
  sed -i "s/<KEY_PAIR>/\"${KEY_PAIR}\"/g" ${TERRAFORM_VAR_FILE}
  sed -i "s#<KEY_PAIR_FILE>#\"${KEY_PAIR_FILE}\"#g" ${TERRAFORM_VAR_FILE}
fi

echo "Creating ec2 instance"
cd ${BASE_DIR}/terraform
if [ ! -d "./.terraform" ]; then 
  echo "executing 'terraform init'" 	  
  terraform init  
fi 

terraform plan -out=tfplan -input=false 

if [ -f "./tfplan" ]; then 
  echo "Excecuting 'terraform plan'" 	    
  terraform apply "tfplan"
else 
  echo "No terraform plan found! Exiting" 	  
  exit 1 
fi