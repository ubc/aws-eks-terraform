# This section was added to lock the specific version of Terraform providers
# terraform init upgrades providers to the latest versions which sometimes break the configuraiton
terraform {
  reguired_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.95.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }  
  }
}
provider "aws" {
  profile = var.profile
  region = var.region

  assume_role {
    role_arn = var.assume_role_arn
  }
}

provider "random" {
}

provider "local" {
}

provider "null" {
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = flatten(["eks", "get-token", "--cluster-name", module.eks.cluster_name,
      var.assume_role_arn != "" ? ["--role-arn", var.assume_role_arn] : []])
    command     = "aws"
  }
}
