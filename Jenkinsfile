pipeline {
    agent any
    environment {
        ANSIBLE_SERVER = '172.232.96.211'
        REMOTE_PATH = '/root/ansible_deploy'
    }
    
    stages {
        stage('Setup Remote Environment') {
            steps {
                sshagent(['ansible-server-key']) {
                    echo "Creating remote directory: ${REMOTE_PATH}"
                    sh 'ssh root@${ANSIBLE_SERVER} "mkdir -p ${REMOTE_PATH}"'
                    
                    echo "Copying setup script to remote server"
                    sh 'scp ansible/ansible-server-setup.sh root@${ANSIBLE_SERVER}:${REMOTE_PATH}/ansible-server-setup.sh'
                    
                    echo "Executing setup script on remote server"
                    sh '''
                        ssh root@${ANSIBLE_SERVER} "chmod +x ${REMOTE_PATH}/ansible-server-setup.sh && \
                        ${REMOTE_PATH}/ansible-server-setup.sh"
                    '''
                }
            }
        }
        
        stage('Copy Ansible Files') {
            steps {
                sshagent(['ansible-server-key']) {
                    echo "Copying Ansible files to remote server"
                    sh 'scp -r ansible/* root@${ANSIBLE_SERVER}:${REMOTE_PATH}'

                    echo "Transferring EC2 private key"
                    withCredentials([sshUserPrivateKey(credentialsId: 'ec2-server-key', keyFileVariable: 'SSH_KEY')]) {
                        sh '''
                        scp $SSH_KEY root@${ANSIBLE_SERVER}:${REMOTE_PATH}/mydevops.pem
                        ssh root@${ANSIBLE_SERVER} "chmod 400 ${REMOTE_PATH}/mydevops.pem"
                        '''
                    }
                }
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                sshagent(['ansible-server-key']) {
                    echo "Executing Ansible playbook"
                    sh 'ssh root@${ANSIBLE_SERVER} "cd ${REMOTE_PATH} && ansible-playbook my-playbook.yaml"'
            }
        }
    }
    
    post {
        always {
            echo "Cleaning up sensitive files from remote server"
            sshagent(['ansible-server-key']) {
                sh 'ssh root@${ANSIBLE_SERVER} "rm -f ${REMOTE_PATH}/mydevops.pem"'
            }
        }
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed. Check logs for details."
        }
    }
}
}