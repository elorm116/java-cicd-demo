pipeline {
    agent any

    tools {
        maven 'maven-3.9'
    }

    environment {
        IMAGE_VERSION = ''
    }

    stages {
        stage('Increment version') {
            steps {
                script {
                    echo 'Incrementing app version...'
                    // Increment the Maven project version
                    sh '''
                        mvn build-helper:parse-version versions:set \
                        -DnewVersion=\\${parsedVersion.majorVersion}.\\${parsedVersion.minorVersion}.\\${parsedVersion.nextIncrementalVersion} \
                        versions:commit
                    '''
                    
                    // Read version from pom.xml reliably
                    def pom = readMavenPom file: 'pom.xml'
                    env.IMAGE_VERSION = pom.version
                    echo "Set IMAGE_VERSION to: ${env.IMAGE_VERSION}"
                }
            }
        }

        stage('Build app') {
            steps {
                script {
                    echo "Building the application..."
                    sh 'mvn clean package'
                }
            }
        }

        stage('Build Docker image') {
            steps {
                script {
                    echo "Building Docker image with tag: ${env.IMAGE_VERSION}"
                    withCredentials([usernamePassword(credentialsId: 'docker-nexus-repo', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh "docker build -t host.docker.internal:8083/my-app:${env.IMAGE_VERSION} ."
                        sh "echo \$PASS | docker login host.docker.internal:8083 -u \$USER --password-stdin"
                        sh "docker push host.docker.internal:8083/my-app:${env.IMAGE_VERSION}"
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    echo 'Deploying Docker image to EC2...'
                    // Deployment steps go here
                }
            }
        }

        stage('Commit version update') {
            steps {
                script {
                    // **Git part is untouched as requested**
                    withCredentials([string(credentialsId: 'github-integration', variable: 'GITHUB_TOKEN')]) {
                        sh 'git config user.email "jenkins@ci.com"'
                        sh 'git config user.name "Jenkins CI"'
                        sh "git remote set-url origin https://elorm116:\${GITHUB_TOKEN}@github.com/elorm116/java-cicd-demo.git"
                        sh 'git add .'
                        sh 'git commit -m "ci: version bump"'
                        sh 'git push origin HEAD:main'
                    }
                }
            }
        }
    }
}
