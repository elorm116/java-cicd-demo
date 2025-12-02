#!/usr/bin/env groovy

pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo "Building project..."
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
                    echo "Deploying application to EC2 instance..."
                    sshagent(['ec2-server-key']) {
                        withCredentials([string(credentialsId: 'github-integration', variable: 'GITHUB_TOKEN')]) {
                            sh """
                                scp -o StrictHostKeyChecking=no docker-compose.yml ec2-user@3.215.186.80:/home/ec2-user/
                                ssh -o StrictHostKeyChecking=no ec2-user@3.215.186.80 << 'ENDSSH'
                                    cd /home/ec2-user/
                                    
                                    # Login to GitHub Container Registry (if needed for private images)
                                    echo "\$GITHUB_TOKEN" | docker login ghcr.io -u elorm116 --password-stdin
                                    
                                    # Deploy using docker-compose
                                    docker-compose down || true
                                    docker-compose up -d
                                    
                                    # Logout from registry
                                    docker logout ghcr.io
ENDSSH
                            """
                        }
                    }
                }
            }
        }
    }
}