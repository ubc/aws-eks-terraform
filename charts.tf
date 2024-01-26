terraform {
  required_version = ">= 1.0.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.8.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
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

  depends_on = [
    module.eks.cluster_name,
    #null_resource.apply,
  ]
}

module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.12"

  count = var.enable_autoscaler ? 1 : 0

  role_name_prefix = "cluster-autoscaler"
  role_description = "IRSA role for cluster autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids   = [module.eks.cluster_name]

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

  depends_on = [
    module.eks.cluster_id,
    #null_resource.apply,
  ]
}


resource "helm_release" "metrics-server" {
  name       = "metrics-server"
  count      = var.enable_metricsserver ? 1 : 0
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "default"

  depends_on = [
    module.eks.cluster_id,
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
    module.eks.cluster_id,
    #null_resource.apply,
  ]
}

resource "helm_release" "container-insights" {
  name             = "container-insights"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-cloudwatch-metrics"
  create_namespace = true
  namespace        = var.observability_namespace
  count            = var.alerts_enabled ? 1 : 0

  depends_on = [
    module.eks.cluster_id
  ]

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "cloudwatch.tolerations[0].key"
    value = "hub.jupyter.org/dedicated"
  }
  set {
    name  = "cloudwatch.tolerations[0].value"
    value = "user"
  }
  set {
    name  = "cloudwatch.tolerations[0].operator"
    value = "Equal"
  }
  set {
    name  = "cloudwatch.tolerations[0].effect"
    value = "NoSchedule"
  }

}

resource "helm_release" "fluent_bit_cloudwatch" {
  name             = "fluent-bit"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-for-fluent-bit"
  create_namespace = true
  namespace        = var.observability_namespace
  count            = var.fluent_bit_enabled ? 1 : 0
  set {
    name  = "cloudWatch.region"
    value = var.region
  }

  set {
    name  = "cloudWatch.logGroupName"
    value = var.fluentbit_group
  }

  set {
    name  = "cloudWatch.logStreamPrefix"
    value = var.fluentbit_stream_name
  }

  set {
    name  = "cloudWatch.logRetentionDays"
    value = "30"
  }

  set {
    name  = "cloudwatch.tolerations[0].key"
    value = "hub.jupyter.org/dedicated"
  }
  set {
    name  = "cloudwatch.tolerations[0].value"
    value = "user"
  }
  set {
    name  = "cloudwatch.tolerations[0].operator"
    value = "Equal"
  }
  set {
    name  = "cloudwatch.tolerations[0].effect"
    value = "NoSchedule"
  }

  depends_on = [
    module.eks.cluster_id
  ]

}

<<<<<<< Updated upstream
=======
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
}
>>>>>>> Stashed changes
