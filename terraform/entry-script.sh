#!/bin/bash
# Wait for instance to fully initialize
sleep 30

# Update system
sudo yum update -y

# Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install AWS CLI (Amazon Linux 2023 should have it, but just in case)
sudo yum install -y awscli

# Verify installations
docker --version
docker-compose --version
aws --version