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
                    sshagent(['ec2-server-key']) {
                        withCredentials([string(credentialsId: 'github-integration', variable: 'GITHUB_TOKEN')]) {
                            sh """
                                ssh -o StrictHostKeyChecking=no -T ec2-user@34.239.177.1 << 'ENDSSH'
                                
# Login to GitHub Container Registry
echo "\$GITHUB_TOKEN" | docker login ghcr.io -u elorm116 --password-stdin

# Pull the latest image
docker pull ghcr.io/elorm116/my-app:v2

# Stop and remove old container
docker stop my-app || true
docker rm my-app || true

# Run new container
docker run -d --name my-app -p 3000:80 ghcr.io/elorm116/my-app:v2

# Logout from registry (security best practice)
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