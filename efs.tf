module "attach_efs_csi_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "efs-csi"
  attach_efs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }
}

# service account
resource "kubernetes_service_account" "efs-csi-service-account" {
  metadata {
    name      = "efs-csi-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "efs-csi-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.attach_efs_csi_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }

  depends_on = [time_sleep.delay_access_policy_associations]
}


resource "aws_efs_file_system" "home" {
  tags = local.tags
}

resource "aws_efs_mount_target" "home_mount" {
  count           = length(module.vpc.private_subnets)
  file_system_id  = aws_efs_file_system.home.id
  subnet_id       = element(module.vpc.private_subnets, count.index)
  security_groups = [aws_security_group.efs_mt_sg.id]
}

resource "aws_security_group" "efs_mt_sg" {
  name_prefix = "aws-sg-efs-${local.cluster_name}"
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

  tags = local.tags
}

resource "aws_efs_file_system" "course" {
  encrypted = true
  tags      = local.tags
}

resource "aws_efs_mount_target" "course_mount" {
  count           = length(module.vpc.private_subnets)
  file_system_id  = aws_efs_file_system.course.id
  subnet_id       = element(module.vpc.private_subnets, count.index)
  security_groups = [aws_security_group.efs_mt_sg.id]
}
