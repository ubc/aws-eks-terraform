#!/bin/bash

# UBC EKS Jumpbox/Bastian Install & Setup Script
# By Rahim Khoja (rahim.khoja@ubc.ca)

echo
echo "---UBC EKS Jumpbox/Bastian Ubuntu Install Script---"
echo "---By: Rahim Khoja (rahim.khoja@ubc.ca)---"
echo

# Requirements: Ubuntu 20.04 LTS (Desktop Minimal)
#               Internet Access

# Stop on Error
set -eE  # same as: `set -o errexit -o errtrace`

# Failure Function
function failure() {
    local lineno=$1
    local msg=$2
    echo ""
    echo -e "\033[0;31mError at Line Number $lineno: '$msg'\033[0m"
    echo ""
}

# Failure Function Trap
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

# Check the bash shell script is being run by root/sudo
if [[ $EUID -ne 0 ]];
then
    echo "This script must be run with sudo" 1>&2
    exit 1
fi

# Simple Check to Confirm the OS is Ubuntu (Checks Kernel Name)
if [[ -z "$(uname -a | grep Ubuntu)" ]]; 
then
    echo "This script must be run on a Ubuntu operating system" 1>&2
    exit 1
fi

# Variables
rname=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo '')
mkdir "/tmp/${rname}"
cd "/tmp/${rname}"

# Apt Installs
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
curl -fsSL https://baltocdn.com/helm/signing.asc | apt-key add -
apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-add-repository "deb https://baltocdn.com/helm/stable/debian/ all main"
apt upgrade --yes
apt install awscli terraform apt-transport-https helm --yes

# Binary Installs
saws_ver=$(curl -Ls https://api.github.com/repos/Versent/saml2aws/releases/latest | grep 'tag_name' | cut -d'v' -f2 | cut -d'"' -f1)
wget -c https://github.com/Versent/saml2aws/releases/download/v${saws_ver}/saml2aws_${saws_ver}_linux_amd64.tar.gz -O - | tar -xzv -C ./
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chown 1000:1000 ./kubectl
chown 1000:1000 ./saml2aws
chmod u+x ./saml2aws
chmod u+x ./kubectl
mv ./kubectl /usr/local/bin/
mv ./saml2aws /usr/local/bin/
hash -r

# Clean Up
cd ~/
rm -rf "/tmp/${rname}"
