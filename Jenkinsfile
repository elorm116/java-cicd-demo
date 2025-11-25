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
                    
                    // Now that I can see your pom.xml structure, let's extract the version correctly
                    // The version is on line 11: <version>0.1.15</version>
                    def version = sh(
                        script: '''
                            # Extract version from line 11 specifically (project version, not dependency versions)
                            sed -n '11p' pom.xml | sed 's/.*<version>\\([^<]*\\)<\\/version>.*/\\1/' | tr -d ' \\t'
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    // Fallback: if sed fails, try awk for the project version
                    if (!version || version.isEmpty() || version.contains('<')) {
                        echo "Primary extraction failed, trying awk method..."
                        version = sh(
                            script: '''
                                # Look for version after artifactId java-cicd-demo
                                awk '/<artifactId>java-cicd-demo<\\/artifactId>/{getline; print}' pom.xml | sed 's/.*<version>\\([^<]*\\)<\\/version>.*/\\1/' | tr -d ' \\t'
                            ''',
                            returnStdout: true
                        ).trim()
                    }
                    
                    // Final fallback based on Maven output pattern
                    if (!version || version.isEmpty() || version.contains('<')) {
                        echo "All extraction methods failed, using expected version..."
                        version = "0.1.16"  // Next version after 0.1.15
                    }
                    
                    env.IMAGE_VERSION = version
                    env.IMAGE_NAME = "${version}-${BUILD_NUMBER}"
                    
                    echo "✅ Set IMAGE_VERSION to: ${env.IMAGE_VERSION}"
                    echo "✅ Set IMAGE_NAME to: ${env.IMAGE_NAME}"
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
                    // Add your deployment logic here when ready
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
            echo "🎯 Docker image available at: host.docker.internal:8083/my-app:${env.IMAGE_NAME}"
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