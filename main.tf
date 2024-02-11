locals {
  validate_environment_cnd = var.environment != terraform.workspace
  validate_environment_msg = "Invalid environment. Must match the workspace name"
  validate_environment_chk = regex(
    "^${local.validate_environment_msg}$",
    (!local.validate_environment_cnd
      ? local.validate_environment_msg
  : ""))
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

#resource "null_resource" "apply" {
#  triggers = {
#    cmd_patch  = <<-EOT
#      kubectl patch configmap/aws-auth --patch "${module.eks.aws_auth_configmap_yaml}" -n kube-system
#    EOT
#  }
#
#  provisioner "local-exec" {
#    interpreter = ["/bin/bash", "-c"]
#    command = self.triggers.cmd_patch
#  }
#}
#



data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

locals {
  cluster_name                  = "${var.cluster_base_name}-${var.environment}"
  k8s_service_account_namespace = "kube-system"
  k8s_service_account_name      = "cluster-autoscaler-aws-cluster-autoscaler-chart"
  tags = {
    Environment  = "${var.environment}"
    project      = "${var.tag_project_name}"
    department   = "${var.tag_department}"
    dept_service = "${var.tag_dept_service}"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "aws_db_instance" "rds" {
  count                  = var.eks_rds_db != "0" ? "1" : "0"
  identifier             = "rds-db-${local.cluster_name}"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  db_name                = "jupyterhub"
  username               = "admin"
  password               = "UBC-Shib-Backend"
  parameter_group_name   = "default.mysql5.7"
  publicly_accessible    = false
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_mysql.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_mysql.name
  tags                   = local.tags
}

resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "aws-sg-wgm-${local.cluster_name}"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }
  tags = local.tags

}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "aws-sg-awm-${local.cluster_name}"
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
  tags = local.tags
}

resource "aws_security_group" "alb_prod_sg" {
  name_prefix = "alb-sg-${local.cluster_name}"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(
    local.tags,
    {
      GithubRepo = "terraform-aws-eks"
      GithubOrg  = "terraform-aws-modules"
    }
  )
}

resource "aws_security_group" "rds_mysql" {
  name_prefix = "rds-db-sg-${local.cluster_name}"
  description = "Allow MySQL Ports"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allowing Connection for MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      GithubOrg = "terraform-aws-modules"
    }
  )
}

resource "aws_db_subnet_group" "rds_mysql" {
  name_prefix = "rds-db-sng-${local.cluster_name}"
  subnet_ids  = module.vpc.public_subnets

  tags = local.tags
}


resource "null_resource" "kube_config_create" {
  depends_on = [module.eks.cluster_name]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "aws eks --region ${var.region} update-kubeconfig --name ${local.cluster_name} && export KUBE_CONFIG_PATH=~/.kube/config && export KUBERNETES_MASTER=~/.kube/config"
  }
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = "vpc-${local.cluster_name}"
  cidr                 = var.vpc_cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = var.vpc_private_subnets
  public_subnets       = var.vpc_public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "project"                                     = "${local.tags.project}"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
    "project"                                     = "${local.tags.project}"
    "interface"                                   = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
    "project"                                     = "${local.tags.project}"
    "interface"                                   = "private"
  }
}

data "aws_subnet" "private_zone1a" {
  availability_zone = "ca-central-1a"
  vpc_id = module.vpc.vpc_id
  filter {
    name   = "tag:interface"
    values = ["private"]
  }
  depends_on = [module.vpc.private_subnets]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.1"

  cluster_name                   = local.cluster_name
  cluster_version                = var.kube_version
  cluster_endpoint_public_access = true
  # Gives Terraform identity admin access to cluster which will
  # allow deploying resources into the cluster
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  iam_role_additional_policies = {
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  subnet_ids                  = module.vpc.private_subnets
  vpc_id                      = module.vpc.vpc_id
  enable_irsa                 = true
  create_cloudwatch_log_group = false
  node_security_group_additional_rules = {
  }

  tags = merge(
    local.tags,
    {
      GithubRepo = "terraform-aws-eks"
      GithubOrg  = "terraform-aws-modules"
    }
  )

  eks_managed_node_group_defaults = {
    disk_size         = var.eks_node_disk_size
    instance_types    = var.eks_instance_types
    instance_type     = var.eks_instance_type
    enable_monitoring = true


    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = var.eks_node_disk_size
          volume_type           = "gp3"
          iops                  = 3500
          throughput            = 150
          encrypted             = true
          delete_on_termination = true
        }
      }
    }
  }

  eks_managed_node_groups = [
    {
      name                          = "mgmt-pods-${var.environment}"
      desired_size                  = var.wg_desired_cap
      min_size                      = var.wg_min_size
      max_size                      = var.wg_max_size
      additional_security_group_ids = [aws_security_group.all_worker_mgmt.id, aws_security_group.rds_mysql.id, aws_security_group.efs_mt_sg.id]
      create_launch_template        = true
      launch_template_name          = ""
      subnet_ids                    = [data.aws_subnet.private_zone1a.id]
      taints = [
#        {
#          key    = "hub.jupyter.org/dedicated"
#          value  = "core"
#          effect = "NO_SCHEDULE"
#        },
        {
          key    = "node-role.kubernetes.io/master"
          effect = "NO_SCHEDULE"
        }
      ]
      tags = merge(
        local.tags,
        {
          "k8s.io/cluster-autoscaler/enabled"               = "true"
          "k8s.io/cluster-autoscaler/${local.cluster_name}" = "true"
        }
      )
    },

    {
      name                          = "user-pods-${var.environment}"
      desired_size                  = var.ug_desired_cap
      min_size                      = var.ug_min_size
      max_size                      = var.ug_max_size
      additional_security_group_ids = [aws_security_group.all_worker_mgmt.id, aws_security_group.rds_mysql.id, aws_security_group.efs_mt_sg.id]
      create_launch_template        = true
      launch_template_name          = ""
      subnet_ids                    = [data.aws_subnet.private_zone1a.id]
      taints = [
        {
          key    = "hub.jupyter.org/dedicated"
          value  = "user"
          effect = "NO_SCHEDULE"
        }
      ]
      tags = merge(
        local.tags,
        {
          "k8s.io/cluster-autoscaler/enabled"               = "true"
          "k8s.io/cluster-autoscaler/${local.cluster_name}" = "true"
        }
      )
    }
  ]
  cluster_additional_security_group_ids = [aws_security_group.all_worker_mgmt.id, aws_security_group.rds_mysql.id, aws_security_group.efs_mt_sg.id]

  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      resolve_conflicts_on_create = "OVERWRITE"
      service_account_role_arn = "${module.ebs_csi_controller_role.iam_role_arn}"
      configuration_values = jsonencode({
        controller: {
          tolerations : [
            {
              key : "node-role.kubernetes.io/master",
              operator : "Equal",
              effect : "NoSchedule"
            }
          ]
        }
      })
    },
    aws-efs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.attach_efs_csi_role.iam_role_arn
      configuration_values = jsonencode({
        controller: {
          tolerations : [
            {
              key : "node-role.kubernetes.io/master",
              operator : "Equal",
              effect : "NoSchedule"
            }
          ]
        }
      })
    }
  }
}

#module "ebs_csi_irsa_role" {
#  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#
#  role_name             = "${module.eks.cluster_name}-ebs-csi"
#  attach_ebs_csi_policy = true
#
#  oidc_providers = {
#    ex = {
#      provider_arn               = module.eks.oidc_provider_arn
#      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
#    }
#  }
#}

resource "aws_iam_role_policy_attachment" "node_role_log_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = module.eks.eks_managed_node_groups[0].iam_role_name
}

