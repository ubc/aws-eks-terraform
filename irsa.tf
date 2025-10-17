module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
# This section was added to lock the version of Terraform modules
# terraform init -upgrade command downloads the newer versions of modules which sometimes break the configuraiton
  version = "5.59.0"
  create_role                   = true
  role_name                     = "cluster-autoscaler-${random_string.suffix.result}"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [
    aws_iam_policy.cluster_autoscaler.arn, 
    aws_iam_policy.ecr_pull_through_cache.arn
  ]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"]
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name_prefix = "cluster-autoscaler"
  description = "EKS cluster-autoscaler policy for cluster ${module.eks.cluster_name}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "clusterAutoscalerOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}


resource "aws_iam_policy" "ecr_pull_through_cache" {
  name_prefix = "ecr-pull-through-cache"
  description = "Allow EKS pods to use ECR pull-through cache (auto-create repos and import images)"
  policy      = data.aws_iam_policy_document.ecr_pull_through_cache.json
}

data "aws_iam_policy_document" "ecr_pull_through_cache" {
  statement {
    sid    = "PullThroughCacheFromReadOnlyRole"
    effect = "Allow"

    actions = [
      "ecr:BatchImportUpstreamImage",
      "ecr:ReplicateImage",
      "ecr:CreateRepository"
    ]

    resources = [
      "arn:aws:ecr:ca-central-1:${data.aws_caller_identity.current.account_id}:repository/quay/*"
    ]
  }
}
