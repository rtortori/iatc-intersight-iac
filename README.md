# Cisco Intersight Infrastructure-as-Code Demo

**Disclaimer**<br>

This is NOT an official Cisco application and comes with absolute NO WARRANTY!<br>
Please check the [LICENSE](https://github.com/rtortori/iatc-intersight-iac/blob/main/LICENSE-CISCO.md) for further information.<br>

**Credits**<br>
This demo has been largely inspired by the great work done by [Ned Bellavance](https://app.pluralsight.com/profile/author/edward-bellavance) for his 'Getting Started' and 'Deep Dive' Terraform courses on Pluralsight. Although it has been mostly reworked and extended to work with Intersight and Vault, some constructs and strategies have been reused in this repository.

### Introduction

The scope of this project is to demonstrate how Cisco Intersight can fit an existing CI/CD environment with centralized secret management and multiple teams sharing resources.<br>
This repository contains the code and the instructions to setup the whole demo on your laptop.<br>
<br>
At the end of the setup you will have:

- Two **GitHub** private repositories, one for the Compute team, one for the Security Team
- A **Jenkins** instance, preconfigured with two pipelines and the necessary credentials and plugins
- A **Vault** instance configured to authenticate on behalf of Consul. This Vault instance will also store your **Intersight** credentials
- A **Consul** instance that stores both compute and security configuration parameters and remote state 

**Notes**<br>

- Once the setup is complete, you can "pause" it to free resources with ```minikube stop``` <br>
- You can resume the demo setup with ```minikube start```. However, you are required to recreate the port-forwarding rules as well as Vault configuration. Since we are running in dev mode, once the pod restarts, it losts all data. (see below to recreate the port-forwarding rules and Vault configuration)<br>
- The first time you run the pipelines, it may take up to 20 minutes as Jenkins will need to download the container agent images for the first time. Subsequent runs should happen much faster. The same is true with the installation of Vault, Consul and Jenkins as minikube will need to download the images first

### Prerequisites

- [minikube](https://minikube.sigs.k8s.io/docs/start/)
- [helm](https://helm.sh/docs/intro/install/)
- awk
- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) 
- [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [consul client](https://www.consul.io/docs/install)
- [vault client](https://www.vaultproject.io/downloads)
- An Intersight secret file (get it from intersight.com, settings -> API keys )
- A [GitHub personal access token](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token)

### Installation

Clone this repository

```
git clone https://github.com/rtortori/iatc-intersight-iac.git
```

Move to the repo directory and delete the existing repository

```
cd iatc-intersight-iac && rm -rf .git
```

Copy your **Intersight** Secret in the demo-setup/intersight directory (replace "/path/to" with the actual directory) 

```
cp /path/to/SecretKey.txt demo-setup/intersight/SecretKey.txt
```

Set the **Intersight** API key as an environment variable

```
export INTERSIGHT_API_TOKEN="your_token_here"
```

Set your **GitHub** token and username as an environment variable<br>
(E.g. GITHUB_USERNAME="rtortori")

```
export GITHUB_TOKEN="your_token_here"
export GITHUB_USERNAME="myuser"
```

Start minikube

```
minikube start
```

Deploy **Consul**

```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install -f ./demo-setup/consul/consul_values.yaml consul hashicorp/consul
```

Deploy **Jenkins**

```
helm repo add jenkins https://charts.jenkins.io
helm repo update
helm install -f ./demo-setup/jenkins/jenkins_values.yaml jenkins jenkins/jenkins
```

Deploy **Vault**

```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault \
    --set "server.dev.enabled=true" \
    --set "injector.enabled=false" \
    --set "ui.enabled=true"
```

Ensure *all* pods are in the 'Running' state. They also need to show '1/1'<br>
If some pods are not ready yet, just wait a few more minutes and retry the command. It may take some time depending on your internet connection<br>

```
kubectl get pods
```


Create the port-forwarding rules to access **Jenkins**, **Vault** and **Consul**

```
kubectl port-forward service/consul-consul-ui 8500:80 --address 0.0.0.0 >/dev/null&
kubectl port-forward service/jenkins 8080:8080 >/dev/null&
kubectl port-forward service/vault-ui 8200:8200 >/dev/null&
```

Set Environment variables to access deployed resources (Vault token will be 'root' as we run it in Dev mode)

```
export CONSUL_HTTP_TOKEN=$(kubectl get secret consul-consul-bootstrap-acl-token -o=jsonpath={.data.token} | base64 -d)
export JENKINS_URL="http://127.0.0.1:8080"
export JENKINS_USERNAME="admin"
export JENKINS_PASSWORD="$(kubectl exec --namespace default -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/chart-admin-password && echo)"
export COOKIE_JAR=/tmp/cookies
export VAULT_TOKEN=root
export VAULT_ADDR='http://0.0.0.0:8200'
```

**Consul** Setup

```
cd demo-setup/consul
terraform init
terraform plan -out consul.tfplan
terraform apply --auto-approve consul.tfplan
```

Create Intersight Compute and Security Configuration in **Consul**

```
consul kv put intersight_compute/configuration/compute_config @compute_config.json
consul kv put intersight_security/configuration/security_config @security_config.json
```

Create an ACL token for Vault to manage **Consul** Authentication

```
export GLOB_MGT_TOKEN=$(consul acl token create -policy-name=global-management | grep SecretID | awk '{print $2}')
```

Enable the consul secret engine in **Vault**

```
vault secrets enable consul
```

Configure **Vault** to authenticate to Consul

```
vault write consul/config/access \
    address=consul-consul-server:8500 \
    token=$GLOB_MGT_TOKEN
```

Configure compute and security roles in **Vault** and map to Consul Policies

```
vault write consul/roles/intersight_compute policies=intersight_compute
vault write consul/roles/intersight_security policies=intersight_security
```

Change Directory to the intersight directory

```
cd ../intersight
```

Write Intersight secrets to **Vault**

```
vault secrets enable -path=intersight kv
vault kv put intersight/credentials/cert cert=@SecretKey.txt
vault kv put intersight/credentials/api_key api_key=$INTERSIGHT_API_TOKEN
```

Configure credentials in **Jenkins**. Set Jenkins crumbs

```
JENKINS_CRUMB=$(curl --silent --cookie-jar $COOKIE_JAR $JENKINS_URL'/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)' -u $JENKINS_USERNAME:$JENKINS_PASSWORD)
```

Set GitHub and Vault Credentials in **Jenkins**. <br>
For this demo we will use the same token, but in production you will have policies and different tokens

```
# GH credentials
curl -X POST "http://$JENKINS_USERNAME:$JENKINS_PASSWORD@127.0.0.1:8080/credentials/store/system/domain/_/createCredentials" --cookie $COOKIE_JAR  -H $JENKINS_CRUMB \
--data-urlencode 'json={
  "": "0",
  "credentials": {
    "scope": "GLOBAL",
    "id": "GitHub_Credentials",
    "username": "dummy",
    "password": "'"$GITHUB_TOKEN"'",
    "description": "GH Credentials",
    "$class": "com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl"
  }
}'

# Vault Compute Credentials
curl -X POST "http://$JENKINS_USERNAME:$JENKINS_PASSWORD@127.0.0.1:8080/credentials/store/system/domain/_/createCredentials" --cookie $COOKIE_JAR  -H $JENKINS_CRUMB \
--data-urlencode 'json={
 "": "0",
  "credentials": { 
  "scope": "GLOBAL", 
  "id": "Intersight_Compute_Vault", 
  "secret": "root", 
  "description": "Vault token for Compute team", 
  "$class": "org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl" 
 }
}' 

# Vault Security Credentials
curl -X POST "http://$JENKINS_USERNAME:$JENKINS_PASSWORD@127.0.0.1:8080/credentials/store/system/domain/_/createCredentials" --cookie $COOKIE_JAR  -H $JENKINS_CRUMB \
--data-urlencode 'json={
 "": "0",
  "credentials": { 
  "scope": "GLOBAL", 
  "id": "Intersight_Security_Vault", 
  "secret": "root", 
  "description": "Vault token for Security team", 
  "$class": "org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl" 
 }
}'
```

You will now need to login to **Jenkins**. Paste the following command and connect with your browser

```
echo "Login to Jenkins at $JENKINS_URL\nUsername: $JENKINS_USERNAME \nPassword: $JENKINS_PASSWORD"
```

Once connected, go to:

- "Manage Jenkins" -> "Global Tool Configuration" -> "Terraform" -> "Add Terraform" -> Set "Name" = terraform 
- "Install from bintray.com" -> Select "Terraform 0.13.5 linux (amd64)" -> Hit "Save"


Switch back to your terminal and move to the **github** directory

```
cd ../github
```

Configure your GitHub token in the terraform configuration file

```
sed -i '' -e "s/my_gh_token/$GITHUB_TOKEN/g" 2_variables.tf
```

Create the **GitHub** repositories and the **Jenkins** pipeline

```
terraform init
terraform plan
terraform apply -auto-approve
```

Move to the team-compute directory

```
cd ../../team-compute
```

Init the Compute repository and push to **GitHub**

```
git init
echo ".terraform/" >> .git/info/exclude
echo "*.tfstate" >> .git/info/exclude
echo "*.tfstate.backup" >> .git/info/exclude
git add .
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/$GITHUB_USERNAME/intersight_iac_demo_compute.git
git push -u origin main
```

Move to the team-security directory

```
cd ../team-security
```

Init the Security repository and push to **GitHub**

```
git init
echo ".terraform/" >> .git/info/exclude
echo "*.tfstate" >> .git/info/exclude
echo "*.tfstate.backup" >> .git/info/exclude
git add .
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/$GITHUB_USERNAME/intersight_iac_demo_security.git
git push -u origin main
```

### Configuration

The Jenkinsfile(s) in both pipelines include most of the variables used by Terraform.<br>
You may want to customize the following - or not :) <br>

- TF\_VAR\_resource_prefix: Each resource created in Intersight will have this prefix
- TV\_VAR\_organization: The name of the Intersight organization you want your resources in. Most likely is going to be 'default' but in some cases you may want to use an alternative organization


### Clean-up

To clean-up objects created in Intersight, just run the security and the compute pipelines (in this order) and when it asks for confirmation, click on 'Abort'. It will execute a ```terraform destroy -auto-approve``` and everything will disappear.<br>

To clean-up the GitHub repositories and delete all traces of this demo

```
cd demo-setup/github && terraform destroy -auto-approve

minikube stop 
minikube delete

unset INTERSIGHT_API_TOKEN
unset GITHUB_TOKEN
unset GITHUB_USERNAME
unset CONSUL_HTTP_TOKEN
unset JENKINS_USERNAME
unset JENKINS_PASSWORD
unset JENKINS_CRUMB
unset COOKIE_JAR
unset VAULT_TOKEN
unset VAULT_ADDR
unset GLOB_MGT_TOKEN
```













