provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

################################################################################
# Cluster Autoscaler
# Based on the official docs at
# https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler
################################################################################

resource "helm_release" "cluster_autoscaler" {
  name             = "cluster-autoscaler"
  namespace        = "kube-system"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  version          = "9.10.8"
  create_namespace = false

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler-aws"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.cluster_autoscaler_irsa.iam_role_arn
    type  = "string"
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = local.cluster_name
  }

  set {
    name  = "autoDiscovery.enabled"
    value = "true"
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  depends_on = [
    module.eks.cluster_id,
    null_resource.apply,
  ]
}

module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.12"

  role_name_prefix = "cluster-autoscaler"
  role_description = "IRSA role for cluster autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids   = [module.eks.cluster_id]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler-aws"]
    }
  }

  tags = local.tags
}

resource "helm_release" "kubecost" {
  name = "kubecost"
  repository = "https://kubecost.github.io/cost-analyzer/"
  chart      = "cost-analyzer"
  namespace  = "default"

  depends_on = [
    module.eks.cluster_id,
    null_resource.apply,
  ]
}

resource "helm_release" "metrics-server" {
  name = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "default"

  depends_on = [
    module.eks.cluster_id,
    null_resource.apply,
  ]
}
