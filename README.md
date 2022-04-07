# UBC (LTHub) Terraform EKS Cluster Deployment

## Description

A lazymans Terraform deployment of an AWS EKS cluster with Managed Hosts and Autoscaling. 


## Requirements

1. LThub UBC AWS account access. (Or a regular AWS Admin account)

2. saml2aws (https://github.com/Versent/saml2aws)

3. AWS Cli (https://github.com/aws/aws-cli)

4. kubectl (https://kubernetes.io/docs/tasks/tools/)

5. helm (https://helm.sh/docs/intro/install/)

6. terraform (https://learn.hashicorp.com/tutorials/terraform/install-cli)

7. A client system with internet access. 


## Deployment 

### (Optional) Setup Client

   In order to deploy the cluster you will need a client, with the software listed in the **Requirements** section installed, and an internet connection. 
   
   It may be wize to setup an EC2 VM as a Bastion/Jumpbox to be used as the client. If this is prefered, Deploy a Debian or Ubuntu VM and run the following commands on it.

   ```bash
   $ git clone https://github.com/ubc/aws-eks-terraform.git my-first-eks-cluster
   $ cd my-first-eks-cluster
   $ sudo bash ./setup.sh
   ```

### Clone Repo

   These commands may not be needed if the commands in the **Setup Client** section were run.

   ```bash
   $ git clone https://github.com/ubc/aws-eks-terraform.git my-first-eks-cluster
   $ cd my-first-eks-cluster
   ```

### Login via Saml2AWS or AWS CLI Keys

### (Optional) List AWS Profiles

   Helps find the profile name required in the next step. If you have more than one profile, ensure the correct one is chosen in the next step.

   ```bash
   $ cat ~/.aws/credentials | grep -o '\[[^]]*\]'
   ```

### Update Variables File

   Open the **"variables.tf"** file and edit the apropriate variable values to meet your requirements.
   
   **The most important variables to be updated are:**
   
* region              (AWS Region for EKS Cluster)
* profile             (AWS Profile Name to be used to deploy the EKS Cluster)
* eks_instance_types  (A List of Instance Types available to the Node Groups)
* eks_instance_type   (The Default Node Group Instance Type from eks_instance_types list)
* cluster_base_name   (The Base Name used for EKS Cluster Deployment)
* tag_project_name    (A Project Name that is Tagged onto the EKS Cluster Deployment)
     
 **Notes:**
 Some regions do not have the same Instance Types as others. During deployment you may encouter a terraform error stating which instance types are incompatible. Remove the incompatible instance types from the variable "eks_instance_types" and ensure that the variable "eks_instance_type" is set to one of the Instance Types listed in the variable "eks_instance_types".

### Deploy Cluster

  Deploy the EKS Cluster with terraform. If anything goes wrong with the deployment, you can cleanup by following the "Destroy Cluster" step.

   ```bash
   $ saml2aws login  # (Comment out for non Saml2AWS deployment) 
   $ terraform init -upgrade
   $ terraform apply
   ```

### (Optional) Get Kube Config File

   This will be automatically run during the deployment. However if something goes wrong this command may be usefull. 
   
   ```bash
   $ aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name) --profile $(terraform output -raw profile) && export KUBE_CONFIG_PATH=~/.kube/config && export KUBERNETES_MASTER=~/.kube/config
   ```   
   
### Check Deployment

   If these commands complete without errors, the deployment is complete!

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

## References

  - https://github.com/ubc/k8s-syzygy-eks
  - https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/examples/irsa_autoscale_refresh
