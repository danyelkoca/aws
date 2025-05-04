#!/bin/bash
set -e

echo 'Setting AWS CLI auto-prompt...'
export AWS_CLI_AUTO_PROMPT=on-partial

echo 'Setting VENV'
python3 -m venv .venv
echo 'Activating VENV'
source .venv/bin/activate

echo 'Installing Python dependencies'
pip install -r requirements-dev.txt

echo 'Installing AWS CLI...'
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

echo 'Installing Node.js 18.x... for AWS CDK'
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

echo 'Installing AWS CDK...'
sudo npm install -g aws-cdk

echo 'Installing Terraform...'
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install -y terraform