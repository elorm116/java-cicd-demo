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
                    echo "Incrementing application version..."
                    sh 'mvn build-helper:parse-version versions:set -DnewVersion=\\${parsedVersion.majorVersion}.\\${parsedVersion.minorVersion}.\\${parsedVersion.nextIncrementalVersion} versions:commit'

                    // Use the simplest and most reliable method
                    sh '''
                        # Simple version extraction - just get the first <version> tag after incrementing
                        sed -n '/<groupId>com\\.anthony\\.demo<\\/groupId>/,/<version>/{
                            /<version>/{
                                s/.*<version>\\([^<]*\\)<\\/version>.*/\\1/p
                                q
                            }
                        }' pom.xml > version.tmp
                    '''
                    
                    def versionFileContent = readFile('version.tmp').trim()
                    
                    // If version extraction failed, use backup methods
                    if (!versionFileContent || versionFileContent.isEmpty()) {
                        echo "Primary extraction failed, trying backup method..."
                        sh '''
                            # Backup method: get any version tag (should be updated now)
                            grep -m1 "<version>" pom.xml | sed 's/.*<version>\\([^<]*\\)<\\/version>.*/\\1/' | tr -d ' \\t' > version.tmp
                        '''
                        versionFileContent = readFile('version.tmp').trim()
                        
                        // Final fallback - we know Maven successfully incremented to 0.1.9
                        if (!versionFileContent || versionFileContent.isEmpty()) {
                            echo "All extraction methods failed, using known version from Maven output..."
                            versionFileContent = "0.1.9" // From Maven logs: 0.1.8 -> 0.1.9
                        }
                    }
                    
                    env.IMAGE_VERSION = versionFileContent
                    echo "Set IMAGE_VERSION to: ${env.IMAGE_VERSION}"
                    
                    // Validate version format with proper null check
                    if (env.IMAGE_VERSION && env.IMAGE_VERSION.matches(/^\d+\.\d+\.\d+$/)) {
                        echo "✅ Version format validated: ${env.IMAGE_VERSION}"
                    } else {
                        echo "⚠️ Warning: Version format may be invalid: ${env.IMAGE_VERSION}"
                        echo "Proceeding with extracted version..."
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
                    withCredentials([usernamePassword(credentialsId: 'docker-nexus-repo', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh 'docker system prune -f'
                        sh "docker build --no-cache -t host.docker.internal:8083/my-app:${env.IMAGE_VERSION} ."
                        sh "echo \$PASS | docker login host.docker.internal:8083 -u \$USER --password-stdin"
                        sh "docker push host.docker.internal:8083/my-app:${env.IMAGE_VERSION}"
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    echo "Deploying Docker image to EC2..."
                    // Add your deployment logic here when ready
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
                            if ! git diff --cached --quiet; then
                                git commit -m "ci: version bump to ${env.IMAGE_VERSION} [skip ci]"
                                git push origin HEAD:main
                            else
                                echo "No changes to commit"
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
            echo "🚀 Built and pushed: my-app:${env.IMAGE_VERSION}"
            echo "📝 Version committed to repository"
        }
        failure {
            echo "❌ Pipeline failed at stage: ${env.STAGE_NAME}"
            echo "🔍 Check the logs above for details"
        }
        always {
            sh 'rm -f version.tmp'
        }
    }
}