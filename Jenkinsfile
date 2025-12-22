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
        stage('build app') {
            steps {
               script {
                   echo "building the application..."
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
                    sh 'envsubst < kubernetes/deployment.yaml | kubectl apply -f -'
                    sh 'envsubst < kubernetes/service.yaml | kubectl apply -f -'
                }
            }
        }
    }
}
