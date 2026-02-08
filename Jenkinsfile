pipeline {
    agent any

    stages {
        stage('Copy files to ansible server') {
            steps {
                echo 'Copying files to ansible server...'
                script {
                    // Use the 'sshagent' step to provide SSH credentials
                    sshagent(['ansible-server-key']) {
                        // Use 'sh' to execute the scp command
                        sh '''
                            scp -o StrictHostKeyChecking=no ansible/* root@172.235.5.161:/root
                            withCredentials([sshUserPrivateKey(credentialsId: 'ec2-server-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                                sh "scp ${SSH_KEY} root@172.235.5.161:/root/mydevops.pem"
                            }
                        '''
                    }
                }
            }
        }
        stage('Test') {
            steps {
                echo 'Testing...'
                // Add your test steps here
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying...'
                // Add your deploy steps here
            }
        }
    }
}