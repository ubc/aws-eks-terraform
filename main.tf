terraform {
}

provider "aws" {
    profile = var.profile
    region  = var.region
}

provider "random" {
}

provider "local" {
}

provider "null" {
}

provider "template" {
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

resource "null_resource" "apply" {
  triggers = {
    cmd_patch  = <<-EOT
      kubectl patch configmap/aws-auth --patch "${module.eks.aws_auth_configmap_yaml}" -n kube-system
    EOT
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = self.triggers.cmd_patch
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

locals {
  cluster_name = "${var.cluster_base_name}-${random_string.suffix.result}"
  k8s_service_account_namespace = "kube-system"
  k8s_service_account_name      = "cluster-autoscaler-aws-cluster-autoscaler-chart"
  tags = {
    Environment = "${var.tag_enviroment_name}"
    project     = "${var.tag_project_name}"
  }
}

resource "random_string" "suffix" {
  length = 8
  special = false
}

resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16"
    ]
  }
}

resource "null_resource" "kube_config_create" {
  depends_on = [module.eks.cluster_id]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "/usr/bin/aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_id) --profile $(terraform output -raw profile) && export KUBE_CONFIG_PATH=~/.kube/config && export KUBERNETES_MASTER=~/.kube/config"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name                 = "eks-vpc"
  cidr                 = "10.1.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets       = ["10.1.101.0/24", "10.1.102.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "project" = "${local.tags.project}"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
    "project"                                      = "${local.tags.project}"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
    "project"                                     = "${local.tags.project}"
  }
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_version = "1.21"
  version = "18.17.0"
  cluster_name = local.cluster_name

  subnet_ids = module.vpc.private_subnets

  tags = merge(
    local.tags,
    {
      GithubRepo = "terraform-aws-eks"
      GithubOrg = "terraform-aws-modules"
    }
  )

  vpc_id = module.vpc.vpc_id

  enable_irsa = true

  eks_managed_node_group_defaults = {
    disk_size = 72
    instance_types = [var.eks_node_type]
  }

  eks_managed_node_groups = [
    {
      name                      = "wg-${local.cluster_name}-1"
      desired_capacity          = var.wg_desired_cap
      min_size                  = var.wg_min_size
      max_size                  = var.wg_max_size
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
      launch_template_name = ""
      tags = merge(
        local.tags,
        {
          "k8s.io/cluster-autoscaler/enabled"               = "true"
          "k8s.io/cluster-autoscaler/${local.cluster_name}" = "true"
        }
      )
    },
    {
      name                      = "ug-${local.cluster_name}-1"
      desired_capacity          = var.ug_desired_cap
      min_size                  = var.ug_min_size
      max_size                  = var.ug_max_size
      launch_template_name = ""
      tags = merge(
        local.tags,
        {
          "k8s.io/cluster-autoscaler/enabled"               = "true"
          "k8s.io/cluster-autoscaler/${local.cluster_name}" = "true"
        }
      )
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    }
  ]

  cluster_additional_security_group_ids = [aws_security_group.all_worker_mgmt.id]
}

resource "aws_efs_file_system" "home" {
}

resource "aws_efs_mount_target" "home_mount" {
  count           = length(module.vpc.private_subnets)
  file_system_id  = aws_efs_file_system.home.id
  subnet_id       = element(module.vpc.private_subnets, count.index)
  security_groups = [aws_security_group.efs_mt_sg.id]
}

resource "aws_security_group" "efs_mt_sg" {
  name_prefix = "efs_mt_sg"
  description = "Allow NFSv4 traffic"
  vpc_id      = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"

    cidr_blocks = [
      "10.1.0.0/16"
    ]
  }
}
