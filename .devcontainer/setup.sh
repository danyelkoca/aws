#!/bin/bash
set -e

# Python & virtual environment
echo "[*] Setting up Python virtual environment..."
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt

# AWS CLI
echo "[*] Installing AWS CLI..."
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Node.js & AWS CDK
echo "[*] Installing Node.js and AWS CDK..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g aws-cdk

# Terraform
echo "[*] Installing Terraform..."
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -qO- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install -y terraform