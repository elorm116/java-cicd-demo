#!/bin/bash
set -eux

dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user

#Install docker-compose
DOCKER_COMPOSE_VERSION="v2.24.5"

curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
chmod +x /usr/local/bin/docker-compose
