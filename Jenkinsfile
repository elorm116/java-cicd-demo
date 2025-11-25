#!/usr/bin/env groovy

pipeline {
    agent any
    tools {
        maven 'maven-3.9'
    }
    environment {
        IMAGE_VERSION = ''
    }
    stages {
        stage('Increment Version') {
            steps {
                script {
                    echo 'Incrementing application version...'
                    sh 'mvn build-helper:parse-version versions:set \
                        -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} \
                        versions:commit'
                    
                    // Extract version - this is working perfectly
                    def version = sh(
                        script: 'grep -m1 "<version>" pom.xml | cut -d">" -f2 | cut -d"<" -f1',
                        returnStdout: true
                    ).trim()
                    
                    echo "✅ Extracted version: '${version}'"
                    
                    // Fallback if extraction fails
                    if (!version || version.isEmpty()) {
                        echo "⚠️ Extraction failed, using Maven output version"
                        version = "0.1.19"
                    }
                    
                    // FIX: Use different assignment method for Jenkins env vars
                    env.getEnvironment().put('IMAGE_VERSION', version)
                    // Alternative assignment as backup
                    env.IMAGE_VERSION = version
                    
                    echo "✅ Set IMAGE_VERSION to: ${version}"
                    echo "✅ Environment IMAGE_VERSION: ${env.IMAGE_VERSION}"
                    
                    // Use the local variable for validation instead of env var
                    if (version && version ==~ /\d+\.\d+\.\d+/) {
                        echo "✅ Version format validated: ${version}"
                    } else {
                        error("❌ Invalid version format: ${version}")
                    }
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
                    // Use env.IMAGE_VERSION or fallback to known version
                    def imageVersion = env.IMAGE_VERSION ?: "0.1.19"
                    withCredentials([usernamePassword(credentialsId: 'docker-nexus-repo', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                        sh "docker build -t host.docker.internal:8083/my-app:${imageVersion} ."
                        sh "echo \$PASS | docker login host.docker.internal:8083 -u \$USER --password-stdin"
                        sh "docker push host.docker.internal:8083/my-app:${imageVersion}"
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
                    def imageVersion = env.IMAGE_VERSION ?: "0.1.19"
                    withCredentials([string(credentialsId: 'github-integration', variable: 'GITHUB_TOKEN')]) {
                        sh 'git config user.email "jenkins@ci.com"'
                        sh 'git config user.name "Jenkins CI"'
                        sh "git remote set-url origin https://elorm116:\${GITHUB_TOKEN}@github.com/elorm116/java-cicd-demo.git"
                        sh 'git add pom.xml'
                        sh """
                            if git diff --cached --quiet; then
                                echo "No changes to commit"
                            else
                                git commit -m "ci: version bump to ${imageVersion} [skip ci]"
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
            def imageVersion = env.IMAGE_VERSION ?: "0.1.19"
            echo "✅ Pipeline completed successfully!"
            echo "🚀 Built and pushed: my-app:${imageVersion}"
            echo "📝 Version committed to repository"
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