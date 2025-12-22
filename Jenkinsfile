#!/usr/bin/env groovy

pipeline {
    agent any
    tools {
        maven 'maven-3.9' 
    }
    
    environment {
        IMAGE_TAG = "${BUILD_NUMBER}"
        IMAGE_NAME = "867344472959.dkr.ecr.us-east-1.amazonaws.com/js-docker-demo"
        IMAGE_REPO = "867344472959.dkr.ecr.us-east-1.amazonaws.com/js-docker-demo"
        APP_NAME = "my-app"
        REGISTRY = "867344472959.dkr.ecr.us-east-1.amazonaws.com"
        AWS_REGION = "us-east-1"
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
                    withCredentials([
                        string(credentialsId: 'aws_access_id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws_secret', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh """
                            # Login to ECR
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${REGISTRY}
                            
                            # Build Docker images
                            docker build --platform linux/amd64 -t ${IMAGE_NAME}:${IMAGE_TAG} .
                            docker build --platform linux/amd64 -t ${IMAGE_NAME}:latest .
                            
                            # Push to ECR
                            docker push ${IMAGE_NAME}:${IMAGE_TAG}
                            docker push ${IMAGE_NAME}:latest
                            
                            # Logout
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
                    withCredentials([
                        string(credentialsId: 'aws_access_id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws_secret', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh """
                            # Get ECR token and create registry secret
                            ECR_TOKEN=\$(aws ecr get-login-password --region ${AWS_REGION})
                            
                            kubectl create secret docker-registry my-registry-key \\
                                --docker-server=${REGISTRY} \\
                                --docker-username=AWS \\
                                --docker-password=\$ECR_TOKEN \\
                                --dry-run=client -o yaml | kubectl apply -f -
                            
                            # Deploy to Kubernetes
                            envsubst < kubernetes/deployment.yaml | kubectl apply -f -
                            envsubst < kubernetes/service.yaml | kubectl apply -f -
                            
                            # Wait for rollout to complete
                            kubectl rollout status deployment/\${APP_NAME} --timeout=300s
                        """
                    }
                }
            }
        }
    }
}
