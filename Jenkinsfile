pipeline {
    agent any
    
    stages {
        stage('Copy files to ansible server') {
            steps {
                script {
                    // 1. Provide the key to access the Linode
                    sshagent(['ansible-server-key']) {
                        
                        // 2. Copying the general ansible project files
                        sh 'scp -o StrictHostKeyChecking=no ansible/* root@172.232.96.211:/root'
                        
                        // 3. Getting the EC2 key from Jenkins vault and copying it over to the ansible server on Linode
                        withCredentials([sshUserPrivateKey(credentialsId: 'ec2-server-key', keyFileVariable: 'SSH_KEY')]) {
                            sh 'scp -o StrictHostKeyChecking=no $SSH_KEY root@172.232.96.211:/root/mydevops.pem'
                            
                            // IMPORTANT: Set correct permissions on the key once it's on the Linode
                            sh "ssh root@172.232.96.211 'chmod 400 /root/mydevops.pem'"
                        }
                    }
                }
            }
        }
        
        stage('Calling Ansible Playbook') {
            steps {
                echo 'Calling Ansible Playbook...'
                sshagent(['ansible-server-key']) {
                    sh "ssh root@172.232.96.211 'ansible-playbook /root/ansible/my-playbook.yaml'"
                }
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