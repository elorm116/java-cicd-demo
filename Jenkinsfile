pipeline {
    agent any
    environment {
        ANSIBLE_SERVER = '172.232.96.211'
        REMOTE_PATH = '/root/ansible_deploy' // Specific directory
    }
    
    stages {
        stage('Setup Remote Environment') {
            steps {
                sshagent(['ansible-server-key']) {
                    // Create the directory if it doesn't exist
                    sh 'ssh root@${ANSIBLE_SERVER} "mkdir -p ${REMOTE_PATH}"'
                    
                    // Copy playbooks
                    sh 'scp -r ansible/* root@${ANSIBLE_SERVER}:${REMOTE_PATH}'
                    
                    // Handle the EC2 key
                    withCredentials([sshUserPrivateKey(credentialsId: 'ec2-server-key', keyFileVariable: 'SSH_KEY')]) {
                        sh '''
                        scp $SSH_KEY root@${ANSIBLE_SERVER}:${REMOTE_PATH}/mydevops.pem
                        ssh root@${ANSIBLE_SERVER} "chmod 400 ${REMOTE_PATH}/mydevops.pem"
                        '''
                    }
                }
            }
        }
        
        stage('Execute Playbook') {
            steps {
                sshagent(['ansible-server-key']) {
                    // Run the playbook from the specific directory
                    sh '''
                        ssh root@${ANSIBLE_SERVER} "cd ${REMOTE_PATH} && \
                        ansible-playbook my-playbook.yaml"
                    '''
                }
            }
        }
    }
    post {
        always {
            //Cleanup the sensitive key from the remote server after the run
            sshagent(['ansible-server-key']) {
                sh 'ssh root@${ANSIBLE_SERVER} "rm -f ${REMOTE_PATH}/mydevops.pem"'
            }
        }
    }
}