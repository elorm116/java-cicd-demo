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
                    
                    // Try the simple regex method first (from example)
                    def version = ""
                    try {
                        def matcher = readFile('pom.xml') =~ /<version>([^<]+)<\/version>/
                        if (matcher) {
                            // Get the first version after our groupId (should be project version)
                            def pomContent = readFile('pom.xml')
                            def projectSection = pomContent =~ /(?s)<groupId>com\.anthony\.demo<\/groupId>.*?<version>([^<]+)<\/version>/
                            if (projectSection) {
                                version = projectSection[0][1].trim()
                            } else {
                                version = matcher[0][1].trim()
                            }
                        }
                    } catch (Exception e) {
                        echo "Regex extraction failed: ${e.message}"
                    }
                    
                    // Fallback to your shell method if regex fails
                    if (!version || version.isEmpty()) {
                        echo "Trying shell extraction..."
                        version = sh(
                            script: 'grep -m1 "<version>" pom.xml | sed "s/.*<version>\\([^<]*\\)<\\/version>.*/\\1/" | tr -d " \\t"',
                            returnStdout: true
                        ).trim()
                    }
                    
                    // Final fallback
                    if (!version || version.isEmpty()) {
                        version = "0.1.13"  // Update based on current version
                        echo "⚠️ All extraction methods failed, using fallback: ${version}"
                    }
                    
                    env.IMAGE_VERSION = version
                    env.IMAGE_NAME = "${version}-${BUILD_NUMBER}"  // Add build number like the example
                    
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
        }
        failure {
            echo "❌ Pipeline failed"
            echo "🔍 Check the logs above for details"
        }
    }
}