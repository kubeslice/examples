#!/usr/bin/env bash

echo "Updating apt db"
sudo apt update -y

echo "Cloning kubeslice repo"
git clone https://github.com/kubeslice/examples.git /tmp/examples

cd /tmp/examples
git checkout ec2

echo "Installing dependencies"
chmod +x /tmp/examples/ec2/install_dependencies.sh
cd /tmp/examples/ec2; ./install_dependencies.sh
# sudo usermod -aG docker $USER

echo "Installing kubeslice"
chmod +x /tmp/examples/kind/kind.sh
cd /tmp/examples/kind; ./kind.sh

echo "Deploying bookinfo app"
chmod +x /tmp/examples/kind/bookinfo/bookinfo.sh
cd /tmp/examples/kind/bookinfo; ./bookinfo.sh 