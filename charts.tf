provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args = flatten(["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region,
        var.assume_role_arn != "" ? ["--role-arn", var.assume_role_arn] : []])
      command     = "aws"
    }
#    load_config_file       = false
  }
}

# It seems the access policy associations has some delay after creations.
# Sleep 30s to allow the association fully applied.
resource "time_sleep" "delay_access_policy_associations" {
  depends_on = [module.eks.access_policy_associations]

  create_duration = "30s"
}

################################################################################
# Cluster Autoscaler
# Based on the official docs at
# https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler
################################################################################

resource "helm_release" "cluster_autoscaler" {
  name             = "cluster-autoscaler"
  count            = var.enable_autoscaler ? 1 : 0
  namespace        = "kube-system"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  version          = "9.21.1"
  create_namespace = false
  wait             = false

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
    value = module.cluster_autoscaler_irsa[0].iam_role_arn
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

  set {
    name  = "tolerations[0].key"
    value = "node-role.kubernetes.io/master"
  }

  set {
    name  = "tolerations[0].operator"
    value = "Equal"
  }

  set {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }

  depends_on = [
    module.cluster_autoscaler_irsa.iam_role_arn,
    time_sleep.delay_access_policy_associations
    #null_resource.apply,
  ]
}

module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  count = var.enable_autoscaler ? 1 : 0

  role_name_prefix = "cluster-autoscaler"
  role_description = "IRSA role for cluster autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler-aws"]
    }
  }

  tags = local.tags
}

resource "helm_release" "kubecost" {
  name       = "kubecost"
  count      = var.enable_kubecost ? 1 : 0
  repository = "https://kubecost.github.io/cost-analyzer/"
  chart      = "cost-analyzer"
  namespace  = "default"
  wait       = false

  depends_on = [
    time_sleep.delay_access_policy_associations
    #null_resource.apply,
  ]
}

resource "helm_release" "metrics-server" {
  name       = "metrics-server"
  count      = var.enable_metricsserver ? 1 : 0
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "default"
  wait       = false

  set {
    name  = "tolerations[0].key"
    value = "node-role.kubernetes.io/master"
  }

  set {
    name  = "tolerations[0].operator"
    value = "Equal"
  }

  set {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }

  depends_on = [
    module.eks.access_policy_associations
    #null_resource.apply,
  ]
}

resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  count            = var.enable_certmanager ? 1 : 0
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = true
  }

  depends_on = [
    time_sleep.delay_access_policy_associations
    #null_resource.apply,
  ]
}

#resource "helm_release" "container-insights" {
#  name             = "container-insights"
#  repository       = "https://aws.github.io/eks-charts"
#  chart            = "aws-cloudwatch-metrics"
#  create_namespace = true
#  namespace        = var.observability_namespace
#  count            = var.alerts_enabled ? 1 : 0
#
#  depends_on = [
#    module.eks.cluster_name
#  ]
#
#  set {
#    name  = "clusterName"
#    value = var.cluster_name
#  }
#  set {
#    name  = "cloudwatch.tolerations[0].key"
#    value = "hub.jupyter.org/dedicated"
#  }
#  set {
#    name  = "cloudwatch.tolerations[0].value"
#    value = "user"
#  }
#  set {
#    name  = "cloudwatch.tolerations[0].operator"
#    value = "Equal"
#  }
#  set {
#    name  = "cloudwatch.tolerations[0].effect"
#    value = "NoSchedule"
#  }
#
#}

#resource "helm_release" "fluent_bit_cloudwatch" {
#  name             = "fluent-bit"
#  repository       = "https://aws.github.io/eks-charts"
#  chart            = "aws-for-fluent-bit"
#  create_namespace = true
#  namespace        = var.observability_namespace
#  count            = var.fluent_bit_enabled ? 1 : 0
#  set {
#    name  = "cloudWatch.region"
#    value = var.region
#  }
#
#  set {
#    name  = "cloudWatch.logGroupName"
#    value = var.fluentbit_group
#  }
#
#  set {
#    name  = "cloudWatch.logStreamPrefix"
#    value = var.fluentbit_stream_name
#  }
#
#  set {
#    name  = "cloudWatch.logRetentionDays"
#    value = "30"
#  }
#
#  set {
#    name  = "cloudwatch.tolerations[0].key"
#    value = "hub.jupyter.org/dedicated"
#  }
#  set {
#    name  = "cloudwatch.tolerations[0].value"
#    value = "user"
#  }
#  set {
#    name  = "cloudwatch.tolerations[0].operator"
#    value = "Equal"
#  }
#  set {
#    name  = "cloudwatch.tolerations[0].effect"
#    value = "NoSchedule"
#  }
#
#  depends_on = [
#    module.eks.cluster_id
#  ]
#
#}

# resource "helm_release" "kube2iam" {
#   name = "kube2iam"
#   repository = "https://jtblin.github.io/kube2iam"
#   chart = "kube2iam"
#   create_namespace = true
#   namespace = var.kube2iam_namespace
#   count = var.kube2iam_enabled ? 1:0
#

resource "helm_release" "velero" {
  name = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart = "velero"
  create_namespace = true
  namespace = var.velero_namespace
  count = var.velero_enabled ? 1:0
  wait = false

  set {
    name = "configuration.backupStorageLocation[0].name"
    value = "velero-stg"
  }

  set {
    name = "configuration.backupStorageLocation[0].provider"
    value = "aws"
  }

  set {
    name = "configuration.backupStorageLocation[0].bucket"
    value = "velero-jupyterhub"
  }

  set {
    name = "configuration.backupStorageLocation[0].prefix"
    value = "velero-stg"
  }

  set {
    name = "credentials.existingSecret"
    value = "velero-iam"
  }

  set {
    name = "configuration.volumeSnapshotLocation[0].name"
    value = "velero-stg"
  }

  set {
    name = "configuration.volumeSnapshotLocation[0].provider"
    value = "aws"
  }

  set {
    name = "configuration.defaultBackupStorageLocation"
    value = "velero-stg"
  }

  depends_on = [
    time_sleep.delay_access_policy_associations
    #null_resource.apply,
  ]
}
