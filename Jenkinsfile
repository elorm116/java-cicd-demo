#!/usr/bin/env groovy

pipeline {
    agent any
    tools {
        maven 'maven-3.9' 
    }
    
    environment {
        IMAGE_TAG = "${BUILD_NUMBER}"
        IMAGE_NAME = "867344472959.dkr.ecr.us-east-1.amazonaws.com/java-cicd-demo"
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
                            # Use AWS CLI Docker container for ECR login
                            docker run --rm \\
                                -e AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID \\
                                -e AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY \\
                                -e AWS_DEFAULT_REGION=${AWS_REGION} \\
                                amazon/aws-cli:latest \\
                                ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${REGISTRY}
                            
                            # Build and push images
                            docker build --platform linux/amd64 -t ${IMAGE_NAME}:${IMAGE_TAG} .
                            docker push ${IMAGE_NAME}:${IMAGE_TAG}
                            
                            # Logout
                            docker logout ${REGISTRY}
                        """
                    }
                }
            }
        }
        
        stage('provision infra') {
            environment {
                TF_VAR_env_prefix = 'test'
                AWS_ACCESS_KEY_ID = credentials('aws_access_id')
                AWS_SECRET_ACCESS_KEY = credentials('aws_secret')
            }
            steps {
                script {
                    echo 'provisioning infrastructure...'
                    sh """
                        cd terraform
                        terraform init
                        terraform apply -auto-approve
                    """
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
                    echo 'waiting for infra to be ready...'
                    sleep 120
                    echo 'deploying image to EC2...'
                    
                    // Get EC2 public IP from Terraform
                    def ec2Ip = sh(
                        script: 'cd terraform && terraform output -raw aws_instance_public_ip',
                        returnStdout: true
                    ).trim()
                    
                    echo "Deploying to EC2 at: ${ec2Ip}"
                    
                    sshagent(['ec2-server-key']) {
                        // Copy docker-compose file to EC2
                        sh "scp -o StrictHostKeyChecking=no docker-compose.yaml ec2-user@${ec2Ip}:/home/ec2-user/"
                        
                        // SSH and deploy using double quotes for variable expansion
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@${ec2Ip} "
                                # Wait for instance metadata service
                                echo 'Waiting for IAM credentials...'
                                sleep 10
                                
                                # Verify IAM role is attached
                                curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ || echo 'No IAM role found'
                                
                                # Login to ECR using instance profile
                                aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${REGISTRY}
                                
                                # Set image variables and run docker-compose
                                export IMAGE_NAME=${IMAGE_NAME}
                                export IMAGE_TAG=${IMAGE_TAG}
                                
                                # Stop existing containers
                                docker-compose down || true
                                
                                # Pull and run with docker-compose
                                docker-compose up -d
                                
                                # Verify containers are running
                                docker-compose ps
                            "
                        """
                    }
                }
            }
        }
    }
}
