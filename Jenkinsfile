pipeline {
    agent {
        kubernetes {
          label 'terraform'
        }
    }

    parameters {
        string(name: 'environment', defaultValue: 'qa', description: 'Workspace/environment file to use for deployment')
        string(name: 'branch', defaultValue: 'dev', description: 'Branch del repo en github')
        booleanParam(name: 'autoApprove', defaultValue: true, description: 'Automatically run apply after generating plan?')
    }
    
    environment {
        TF_IN_AUTOMATION      = '1'
        GIT_SSH_COMMAND = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
    }

    stages {
	     stage('checkout scm') {
            steps {
                echo 'Revisando repo'
                git branch: "${params.branch}", credentialsId: 'ssh-github-user', url: 'git@github.com:nazpot01/test-greensill-codimd.git'
            }
        }
        stage('Plan') {
            steps {
                script {
                    currentBuild.displayName = params.version
                }
                sshagent (credentials: ['ssh-github-user']) {
                    sh 'terraform --version'
                    sh 'terraform init  -backend-config=backend/config'
                    sh 'terraform workspace select ${environment}'
                    sh 'terraform init  -backend-config=backend/config'
                    sh 'terraform workspace select ${environment}'
                    sh "terraform plan -var-file=variables${params.environment}.tfvars -out=tf.plan"
                    sh 'terraform show -no-color tf.plan > tfplan.txt'
                }
            }
        }

        stage('Approval') {
            when {
                not {
                    equals expected: true, actual: params.autoApprove
                }
            }

            steps {
                script {
                    def plan = readFile 'tfplan.txt'
                    input message: "Do you want to apply the plan?",
                        parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                }
            }
        }

        stage('Apply') {
            steps {
                sh "terraform apply tf.plan"
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'tfplan.txt'
        }
    }
}