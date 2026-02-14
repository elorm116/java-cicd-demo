#!/bin/bash
set -e

echo "========================================="
echo "Setting up Ansible Server"
echo "========================================="

# Helper to check if a command exists
check_command() {
    command -v "$1" &> /dev/null
}

# Update system packages only if they haven't been updated in the last 24h
if [ ! -f /var/lib/apt/periodic/update-success-stamp ] || [ -z "$(find /var/lib/apt/periodic/update-success-stamp -mmin -1440 2>/dev/null)" ]; then
    echo "Updating system packages..."
    apt-get update -y
else
    echo "Skipping apt update (recent update found)"
fi

# Install Python and pip
if ! check_command python3 || ! check_command pip3; then
    echo "Installing Python3 and Pip..."
    apt-get install -y python3 python3-pip
else
    echo "Python3 and Pip already installed"
fi

# Upgrade pip itself first
echo "Ensuring pip is up to date..."
pip3 install --upgrade pip --break-system-packages 2>/dev/null || pip3 install --upgrade pip

# Define Python dependencies
PYTHON_DEPS="awscli boto3 botocore"
echo "Ensuring Python dependencies: $PYTHON_DEPS"
pip3 install $PYTHON_DEPS --upgrade --break-system-packages 2>/dev/null || pip3 install $PYTHON_DEPS --upgrade

# Install/Upgrade Ansible via PPA (Best for Ubuntu)
if ! check_command ansible; then
    echo "Installing Ansible via PPA..."
    apt-get install -y software-properties-common
    apt-add-repository --yes --update ppa:ansible/ansible
    apt-get install -y ansible
else
    echo "Ansible already installed, ensuring latest version..."
    apt-get install -y --only-upgrade ansible 2>/dev/null || echo "Ansible is already at the latest version"
fi

echo ""
echo "========================================="
echo "Verification"
echo "========================================="
echo "Ansible: $(ansible --version | head -n 1)"
echo "AWS CLI: $(aws --version 2>&1)"
echo "Python: $(python3 --version)"
echo "Boto3: $(python3 -c 'import boto3; print(boto3.__version__)')"
echo "Botocore: $(python3 -c 'import botocore; print(botocore.__version__)')"

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="