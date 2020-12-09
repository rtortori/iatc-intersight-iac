pipeline {
    agent any
    tools {
        "org.jenkinsci.plugins.terraform.TerraformInstallation" "terraform"
    }
    parameters {
        string(name: 'CONSUL_STATE_PATH', defaultValue: 'intersight_security/state/current-state', description: 'Path in Consul for state data')
        string(name: 'WORKSPACE', defaultValue: 'development', description:'workspace to use in Terraform')
    }

    environment {
        TF_HOME = tool('terraform')
        TF_INPUT = "0"
        TF_IN_AUTOMATION = "TRUE"
        TF_VAR_consul_address = "consul-consul-server:8500"
        TF_VAR_vault_address = "http://vault-ui:8200"
        TF_VAR_consul_datacenter = "dc1"
        TF_VAR_consul_scheme = "http"
        TF_VAR_vault_token = credentials('Intersight_Security_Vault')
        TF_VAR_resource_prefix = "ric"
        TF_VAR_organization = "default"
        TF_VAR_jobid = "${env.BUILD_ID}"
        TF_LOG = "WARN"
        PATH = "$TF_HOME:$PATH"
    }

    stages {
        stage('Generate Intersight Credentials'){
            steps {
                dir('1_prerequisites/') {
                    sh 'terraform --version'
                    sh 'terraform init'
                    sh 'terraform plan'
                    sh 'terraform apply -auto-approve'
                }
            }
        }
        stage('Initialization'){
            steps {
                dir('2_main/'){
                    sh 'terraform --version'
                    sh "terraform init --backend-config='path=${params.CONSUL_STATE_PATH}'"
                }
            }
        }
        stage('Terraform Validation'){
            steps {
                dir('2_main/'){
                    sh 'terraform validate'
                }
            }
        }
        stage('Plan Configuration'){
            steps {
                dir('2_main/'){
                    script {
                        try {
                           sh "terraform workspace new ${params.WORKSPACE}"
                        } catch (err) {
                            sh "terraform workspace select ${params.WORKSPACE}"
                        }
                        sh "terraform plan -out intersight-security-plan.tfplan;echo \$? > status"
                        stash name: "intersight-security-plan", includes: "intersight-security-plan.tfplan"
                    }
                }
            }
        }
        stage('Apply Configuration'){
            steps {
                script{
                    def apply = false
                    try {
                        input message: 'confirm apply', ok: 'Apply Config'
                        apply = true
                    } catch (err) {
                        apply = false
                        dir('2_main/'){
                            sh "terraform destroy -auto-approve"
                        }
                        currentBuild.result = 'UNSTABLE'
                    }
                    if(apply){
                        dir('2_main/'){
                            unstash "intersight-security-plan"
                            sh 'terraform apply intersight-security-plan.tfplan'
                        }
                    }
                }
            }
        }
    }
}