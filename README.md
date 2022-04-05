# UBC (LTHub) Terraform EKS Cluster Deployment

## Description

## Requirements

1. LThub UBC AWS account access. (Or a regular AWS Admin account)

2. saml2aws (https://github.com/Versent/saml2aws)

3. AWS Cli (https://github.com/aws/aws-cli)

4. kubectl (https://kubernetes.io/docs/tasks/tools/)

5. helm (https://helm.sh/docs/intro/install/)

6. terraform (https://learn.hashicorp.com/tutorials/terraform/install-cli)

7. A client system with internet access. 

## Deployment 

### Clone Repo

   ```bash
   $ git clone https://github.com/ubc/aws-eks-terraform.git
   $ cd aws-eks-terraform
   ```

### (Optional) Setup Client

   ```bash
   $ sudo bash ./setup.sh
   ```

### Login via Saml2AWS or AWS CLI Keys

### (Optional) List AWS Profiles

   Helps find the profile name required in the next step.

   ```bash
   $ cat ~/.aws/credentials | grep -o '\[[^]]*\]'
   ```

### Update Variables File

### Deploy Cluster

  Deploy the EKS Cluster with terraform. If anything goes wrong with the deployment, you can cleanup by following the "Destroy Cluster" step.

   ```bash
   $ saml2aws login  # (Comment out for non Saml2AWS deployment) 
   $ terraform init --upgrade
   $ terraform apply
   ```

### (Optional) Get Kube Config File

   This will be automatically run during the deployment. However if something goes wrong this command may be usefull. Please update the "--profile" option to match your profile name. 
   
   ```bash
   $ aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name) --profile $(terraform output -raw profile) && export KUBE_CONFIG_PATH=~/.kube/config && export KUBERNETES_MASTER=~/.kube/config
   ```   
   
### Check Deployment

   If these commands complete without errors, the deployment is complete!

   ```bash
   $ aws --profile=urn:amazon:webservices --region=us-west-2 eks list-clusters
   ```

   ```bash
   $ kubectl version
   ```
   
   ```bash
   $ kubectl get nodes
   ```
   
   ```bash
   $ kubectl get pods -n kube-system
   ```

### (Optional) Install Helm RBAC

 Some HELM Deployments require Roles to be created. (see the [helm RBAC documentation](https://helm.sh/docs/using_helm/#role-based-access-control) )
 
   ```bash
   $ kubectl create -f rbac-config.yaml --profile urn:amazon:webservices
   $ helm init --service-account tiller --history-max 200
   ```

### (Optional) Destroy Cluster

  Destroy the EKS Cluster with terraform.

   ```bash
   $ saml2aws login  # (Comment out for non Saml2AWS deployment) 
   $ terraform destroy
   ```

## Support

## Refrences
