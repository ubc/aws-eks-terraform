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
  name_prefix = "wg-manager-${local.cluster_name}"
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
  name_prefix = "all-worker-mgmt-${local.cluster_name}"
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
    
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "aws_key_pair" "ssh" {
  key_name_prefix = local.cluster_name
  public_key      = tls_private_key.ssh.public_key_openssh

  provisioner "local-exec" { # Create a "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.ssh.private_key_pem}' > ./${local.cluster_name}.pem"
  }
    
    
  tags = merge(
    local.tags,
    {
      GithubRepo = "terraform-aws-eks"
      GithubOrg = "terraform-aws-modules"
    }
  )
}

resource "aws_security_group" "remote_access" {
  name_prefix = "remote-access-${local.cluster_name}"
  description = "Allow remote SSH access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

   tags = merge(
    local.tags,
    {
      GithubRepo = "terraform-aws-eks"
      GithubOrg = "terraform-aws-modules"
    }
  )   
}
    
resource "aws_security_group" "alb_prod_sg" {
  name_prefix = "alb-prod-sg-${local.cluster_name}"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(
    local.tags,
    {
      GithubRepo = "terraform-aws-eks"
      GithubOrg = "terraform-aws-modules"
    }
  )
}
    
resource "null_resource" "kube_config_create" {
  depends_on = [module.eks.cluster_id]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_id) --profile $(terraform output -raw profile) && export KUBE_CONFIG_PATH=~/.kube/config && export KUBERNETES_MASTER=~/.kube/config"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name                 = "eks-vpc-${local.cluster_name}"
  cidr                 = var.vpc_cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = var.vpc_private_subnets
  public_subnets       = var.vpc_public_subnets
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
  cluster_version = var.kube_version
  version = "18.17.0"
  cluster_name = local.cluster_name
  subnet_ids = module.vpc.private_subnets
  vpc_id = module.vpc.vpc_id
  enable_irsa = true
      
  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
    }
  }
      
  tags = merge(
    local.tags,
    {
      GithubRepo = "terraform-aws-eks"
      GithubOrg = "terraform-aws-modules"
    }
  )

  eks_managed_node_group_defaults = {
    disk_size      = var.eks_node_disk_size
    instance_types = var.eks_instance_types
    instance_type  = var.eks_instance_type
    ami_type       = "AL2_x86_64"
  }

  eks_managed_node_groups = [
    {
      name                      = "wg-${local.cluster_name}-1"
      desired_capacity          = var.wg_desired_cap
      min_size                  = var.wg_min_size
      max_size                  = var.wg_max_size
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id,]
      create_launch_template = false
      launch_template_name   = ""
      remote_access = {
        ec2_ssh_key               = aws_key_pair.ssh.key_name
        source_security_group_ids = [aws_security_group.remote_access.id]
      }
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
  name_prefix = "efs_mt_sg-${local.cluster_name}"
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
