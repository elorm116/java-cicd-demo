#!/usr/bin/env groovy

pipeline {
    agent any
    
    environment {
        IMAGE_TAG = "${BUILD_NUMBER}"
        IMAGE_NAME = "ghcr.io/elorm116/my-app"
        REGISTRY = "ghcr.io"
        GITHUB_USER = "elorm116"
    }

    stages {
        stage('Build') {
            steps {
                script {
                    echo "Building Docker image with tag: ${IMAGE_TAG}"
                    withCredentials([string(credentialsId: 'github-integration', variable: 'GITHUB_TOKEN')]) {
                        sh """
                            # Create and use a multi-platform builder
                            docker buildx create --use --name multiarch --driver docker-container || true
                            
                            # Login to registry first for buildx push
                            echo "\$GITHUB_TOKEN" | docker login ${REGISTRY} -u ${GITHUB_USER} --password-stdin
                            
                            # Build for both AMD64 and ARM64 architectures and push directly
                            docker buildx build --platform linux/amd64,linux/arm64 -t ${IMAGE_NAME}:${IMAGE_TAG} --push .
                            docker buildx build --platform linux/amd64,linux/arm64 -t ${IMAGE_NAME}:latest --push .
                            
                            # Logout from registry
                            docker logout ${REGISTRY}
                        """
                    }
                }
            }
        }

        stage('Push') {
            steps {
                script {
                    echo "Images already pushed during build stage with buildx"
                    // Images are already pushed in build stage when using buildx
                }
            }
        }

        stage('Test') {
            steps {
                echo "Running tests..."
            }
        }

        stage('Deploy') {
            steps {
                script {
                    echo "Deploying application with image tag: ${IMAGE_TAG}"
                    sshagent(['ec2-server-key']) {
                        withCredentials([string(credentialsId: 'github-integration', variable: 'GITHUB_TOKEN')]) {
                            sh """
                                # Update docker-compose.yml with new image tag
                                sed 's|ghcr.io/elorm116/my-app:.*|ghcr.io/elorm116/my-app:${IMAGE_TAG}|g' docker-compose.yaml > docker-compose-deploy.yaml
                                
                                # Copy updated compose file to EC2
                                scp -o StrictHostKeyChecking=no docker-compose-deploy.yaml ec2-user@3.215.186.80:/home/ec2-user/docker-compose.yaml

                                # Deploy on EC2
                                ssh -o StrictHostKeyChecking=no ec2-user@3.215.186.80 "
                                    cd /home/ec2-user/
                                    
                                    # Login to GitHub Container Registry
                                    echo '\$GITHUB_TOKEN' | docker login ${REGISTRY} -u ${GITHUB_USER} --password-stdin
                                    
                                    # Stop existing containers
                                    docker-compose down || true
                                    
                                    # Pull latest image
                                    docker-compose pull
                                    
                                    # Start new containers
                                    docker-compose up -d
                                    
                                    # Clean up old images
                                    docker image prune -f
                                    
                                    # Logout from registry
                                    docker logout ${REGISTRY}
                                "
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                sh """
                    # Clean up buildx builder
                    docker buildx rm multiarch || true
                """
            }
        }
        success {
            echo "Pipeline completed successfully! Deployed image: ${IMAGE_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}