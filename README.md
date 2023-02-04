# Terraform EKS Cluster Deployment


## Description

A lazymans Terraform deployment of an AWS EKS cluster with Managed Hosts and Autoscaling.


## Requirements

1. AWS account with acess to provision resources

2. [saml2aws](https://github.com/Versent/saml2aws)

3. [AWS Cli](https://github.com/aws/aws-cli)  v2.7.1+

4. [kubectl](https://kubernetes.io/docs/tasks/tools/)

5. [helm](https://helm.sh/docs/intro/install/)

6. [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

7. A client system with internet access.


## Deployment

### (Optional) Setup Client

  In order to deploy the cluster you will need a client, with the software listed in the **Requirements** section installed, and an internet connection.

  It may be wize to setup an EC2 VM as a Bastion/Jumpbox to be used as the client. If this is prefered, Deploy a Debian or Ubuntu VM and run the following commands on it.

  ```bash
  $ git clone https://github.com/ubc/aws-eks-terraform.git my-first-eks-cluster
  $ cd my-first-eks-cluster
  $ sudo bash ./support/setup.sh
  ```

### Clone Repo

  These commands may not be needed if the commands in the **Setup Client** section were run.

  ```bash
  $ git clone https://github.com/ubc/aws-eks-terraform.git my-first-eks-cluster
  $ cd my-first-eks-cluster
  ```

### Login via Saml2AWS or AWS CLI Keys
  * Saml2AWS: https://github.com/Versent/saml2aws
  * AWS Keys: https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration

### (Optional) List AWS Profiles

  Helps find the profile name required in the next step. If you have more than one profile, ensure the correct one is chosen in the next step.

  ```bash
  $ cat ~/.aws/credentials | grep -o '\[[^]]*\]'
   ```

### Override Default Variables

  In order to override the default variables in "variables.tf", create a new file **"ENV.tfvar"** (where **"ENV"** is the your environment name, it can be "dev" or "prod"). Add any variables that needs to be overriden.

  **The most important variables are:**

* **region**               - AWS Region for EKS Cluster, e.g. ca-central-1
* **profile**              - AWS Profile Name to be used to deploy the EKS Cluster.
* **eks_instance_types**   - A List of Instance Types available to the Node Groups, e.g. ["t3a.xlarge", "t3a.large"]
* **eks_instance_type**    - The Default Node Group Instance Type from eks_instance_types list, e.g. t3a.large
* **cluster_base_name**    - The Base Name used for EKS Cluster Deployment, e.g. jupyterhub
* **tag_project_name**     - A Project Name that is Tagged onto the EKS Cluster Deployment, e.g. jupyterhub
  **environment**          - Deployment environment, this variable has to match the workspace name, e.g. dev or prod

 **Notes:**
 Some regions do not have the same Instance Types as others. During deployment you may encouter a terraform error stating which instance types are incompatible. Remove the incompatible instance types from the variable "eks_instance_types" and ensure that the variable "eks_instance_type" is set to one of the Instance Types listed in the variable "eks_instance_types".


### Deploy Cluster

  Deploy the EKS Cluster with terraform.

  ```bash
  $ terraform init -upgrade
  $ terraform workspace new ENV          # create a new namespace, replace ENV with the environment name and has to match the "environment" variable
  $ terraform apply -var-file=ENV.tfvar  # replace ENV with the environment name
  ```

 **Notes:**
 Generally if anything goes wrong during deployment its from misconigued variables. You can usually fix this by updating the variables.tf file with the correct infomation and rerunning "terraform apply". If anything goes wrong with the deployment that you cant solve by updaing the variables, you can cleanup by following the **Destroy Cluster** step.


### (Optional) Get Kube Config File

  This will be automatically run during the deployment. However if something goes wrong this command may be usefull.

  ```bash
  $ aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_id) --profile $(terraform output -raw profile) && export KUBE_CONFIG_PATH=~/.kube/config && export KUBERNETES_MASTER=~/.kube/config
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
  $ kubectl get pods -n kube-system  # This should list a Pod with the name "coredns" in the name.
  ```

### (Optional) Destroy Cluster

  Destroy the EKS Cluster with terraform.

  ```bash
  $ saml2aws login  # (Comment out for non Saml2AWS deployment)
  $ terraform destroy -var-file=ENV.tfvar
  ```

## Support

  Please open an issue on GitHub. The support will be based on best effort basis.

## References

  Credit should also go to [PIMS](https://www.pims.math.ca/) and [Ian A.](https://github.com/ianabc) for providing deployments based on AWS EKS.

  - https://github.com/ubc/k8s-syzygy-eks
  - https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/examples/irsa_autoscale_refresh
