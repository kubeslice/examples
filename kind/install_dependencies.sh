#!/usr/bin/env bash

if [ ! $(which ansible) ]; then
  echo "Installing ansible"

#   command -v python3 >/dev/null 2>&1 && python3 -m pip install --user ansible

  if [ $(which python3) ]; then 
    sudo apt update
    sudo apt install -y python3-pip
    # python3 -m pip install --user ansible
    sudo apt install -y ansible
  else 
    echo "python3 not found"
    exit 1
  fi
fi

PATH=$PATH:$(python3 -c "import site; print(site.USER_BASE)")/bin

ansible-playbook -i ./ansible/hosts ansible/main.yaml

# echo "Docker: post-installation steps"
# sudo usermod -aG docker $USER
# newgrp docker 

# bash ${PWD}/kind.sh

exit 0