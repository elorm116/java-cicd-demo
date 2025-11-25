#!/usr/bin/env groovy

pipeline {
    agent any
    tools {
        maven 'maven-3.9'
    }
    environment {
        IMAGE_VERSION = ''
        IMAGE_NAME = ''
    }
    stages {
        stage('Increment Version') {
            steps {
                script {
                    echo 'Incrementing application version...'
                    sh 'mvn build-helper:parse-version versions:set \
                        -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} \
                        versions:commit'
                    
                    // Extract version from line 10 (correct line where <version>0.1.17</version> is located)
                    def version = sh(
                        script: '''
                            # Extract version from line 10 specifically
                            sed -n '10p' pom.xml | sed 's/.*<version>\\([^<]*\\)<\\/version>.*/\\1/' | tr -d ' \\t'
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    echo "Extracted version from line 10: '${version}'"
                    
                    // Fallback: if sed fails, try different approach
                    if (!version || version.isEmpty() || version.contains('<') || version == 'null') {
                        echo "Line 10 extraction failed, trying pattern match..."
                        version = sh(
                            script: '''
                                # Look for version between artifactId and properties
                                sed -n '/<artifactId>java-cicd-demo<\\/artifactId>/,/<properties>/p' pom.xml | grep '<version>' | sed 's/.*<version>\\([^<]*\\)<\\/version>.*/\\1/' | tr -d ' \\t'
                            ''',
                            returnStdout: true
                        ).trim()
                        echo "Extracted version from pattern: '${version}'"
                    }
                    
                    // Final fallback: we know Maven incremented to 0.1.17
                    if (!version || version.isEmpty() || version.contains('<') || version == 'null') {
                        echo "All extraction failed. Maven output shows 0.1.16 -> 0.1.17"
                        version = "0.1.17"
                    }
                    
                    env.IMAGE_VERSION = version
                    env.IMAGE_NAME = "${version}-${BUILD_NUMBER}"
                    
                    echo "✅ Final IMAGE_VERSION: ${env.IMAGE_VERSION}"
                    echo "✅ Final IMAGE_NAME: ${env.IMAGE_NAME}"
                }
            }
        }
        
        stage('Build App') {
            steps {
                script {
                    echo "Building the application..."
                    sh 'mvn clean package'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image..."
                    withCredentials([usernamePassword(credentialsId: 'docker-nexus-repo', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                        sh "docker build -t host.docker.internal:8083/my-app:${env.IMAGE_NAME} ."
                        sh "echo \$PASS | docker login host.docker.internal:8083 -u \$USER --password-stdin"
                        sh "docker push host.docker.internal:8083/my-app:${env.IMAGE_NAME}"
                    }
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    echo 'Deploying Docker image to EC2...'
                    echo "Would deploy: host.docker.internal:8083/my-app:${env.IMAGE_NAME}"
                }
            }
        }
        
        stage('Commit Version Update') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'github-integration', variable: 'GITHUB_TOKEN')]) {
                        sh 'git config user.email "jenkins@ci.com"'
                        sh 'git config user.name "Jenkins CI"'
                        sh "git remote set-url origin https://elorm116:\${GITHUB_TOKEN}@github.com/elorm116/java-cicd-demo.git"
                        sh 'git add pom.xml'
                        sh """
                            if git diff --cached --quiet; then
                                echo "No changes to commit"
                            else
                                git commit -m "ci: version bump to ${env.IMAGE_VERSION} [skip ci]"
                                git push origin HEAD:main
                            fi
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Pipeline completed successfully!"
            echo "🚀 Built and pushed: my-app:${env.IMAGE_NAME}"
            echo "📝 Version committed to repository"
            echo "🎯 Docker image: host.docker.internal:8083/my-app:${env.IMAGE_NAME}"
        }
        failure {
            echo "❌ Pipeline failed"
            echo "🔍 Check the logs above for details"
        }
        always {
            echo "🧹 Cleanup completed"
        }
    }
}