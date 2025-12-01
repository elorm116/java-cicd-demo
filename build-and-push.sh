#!/bin/bash

# Configuration - Updated with your Nexus setup
NEXUS_URL="89690eacab5e.ngrok-free.app"
IMAGE_NAME="my-app"
IMAGE_TAG="${1:-latest}"         # Use first argument as tag, default to 'latest'

# Full image name with registry
FULL_IMAGE_NAME="${NEXUS_URL}/${IMAGE_NAME}:${IMAGE_TAG}"

# Check if NEXUS_USER and NEXUS_PASS environment variables are set
if [ -n "$NEXUS_USER" ] && [ -n "$NEXUS_PASS" ]; then
    echo "Logging into Nexus repository..."
    echo "$NEXUS_PASS" | docker login "$NEXUS_URL" -u "$NEXUS_USER" --password-stdin
    if [ $? -ne 0 ]; then
        echo "Failed to login to Nexus repository!"
        exit 1
    fi
fi

echo "Building Docker image..."
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

if [ $? -ne 0 ]; then
    echo "Docker build failed!"
    exit 1
fi

echo "Tagging image for Nexus repository..."
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${FULL_IMAGE_NAME}"

echo "Pushing image to Nexus repository..."
docker push "${FULL_IMAGE_NAME}"

if [ $? -eq 0 ]; then
    echo "Successfully pushed ${FULL_IMAGE_NAME} to Nexus repository!"
else
    echo "Failed to push image to Nexus repository!"
    exit 1
fi
