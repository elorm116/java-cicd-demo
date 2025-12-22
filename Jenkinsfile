#!/usr/bin/env groovy

pipeline {
    agent any
    tools {
        maven 'maven-3.9' 
    }
    
    environment {
        IMAGE_TAG = "${BUILD_NUMBER}"
        IMAGE_NAME = "ghcr.io/elorm116/my-app"
        IMAGE_REPO = "ghcr.io/elorm116/my-app"
        APP_NAME = "my-app"
        REGISTRY = "ghcr.io"
        GITHUB_USER = "elorm116"
    }
    
    stages {
        stage('build app') {
            steps {
               script {
                   echo "building the application..."
                   sh """
                       mvn clean package
                       ls -la target/
                   """
               }
            }
        }
        
        stage('build image') {
            steps {
                script {
                    echo "building the docker image..."
                    withCredentials([string(credentialsId: 'github-integration', variable: 'GITHUB_TOKEN')]) {
                        sh """
                            echo "\$GITHUB_TOKEN" | docker login ${REGISTRY} -u ${GITHUB_USER} --password-stdin
                            docker build --platform linux/amd64 -t ${IMAGE_NAME}:${IMAGE_TAG} .
                            docker build --platform linux/amd64 -t ${IMAGE_NAME}:latest .
                            docker push ${IMAGE_NAME}:${IMAGE_TAG}
                            docker push ${IMAGE_NAME}:latest
                            docker logout ${REGISTRY}
                        """
                    }
                }
            }
        }
        
        stage('deploy') {
            environment {
               AWS_ACCESS_KEY_ID = credentials('aws_access_id')
               AWS_SECRET_ACCESS_KEY = credentials('aws_secret')
            }
            steps {
                script {
                    echo 'deploying image...'
                    withCredentials([string(credentialsId: 'github-integration', variable: 'GITHUB_TOKEN')]) {
                        sh """
                            kubectl create secret docker-registry my-registry-key \\
                                --docker-server=${REGISTRY} \\
                                --docker-username=${GITHUB_USER} \\
                                --docker-password=\$GITHUB_TOKEN \\
                                --dry-run=client -o yaml | kubectl apply -f -
                            
                            envsubst < kubernetes/deployment.yaml | kubectl apply -f -
                            envsubst < kubernetes/service.yaml | kubectl apply -f -
                        """
                    }
                }
            }
        }
    }
}
