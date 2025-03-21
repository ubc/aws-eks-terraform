variable "region" {
  default = "ca-central-1"
}

variable "profile" {
  description = "AWS profile to use for authentication"
  default     = "default"
}

variable "assume_role_profile" {
  description = "AWS profile to use for AssumeRole for another account, set it the same as profile var to use single AWS account"
  default     = "default"
}

variable "assume_role_arn" {
  description = "AWS ARN for assume role in another account"
  default = ""
}

variable "vpc_cidr" {
  description = "AWS VPC CIDR"
  default     = "10.1.0.0/16"
}

variable "eks_node_disk_size" {
  description = "AWS EKS Node disk size in GB"
  default     = "64"
}

variable "eks_rds_db" {
  description = "Create RDS MySQL Database"
  default     = "0"
}

variable "vpc_private_subnets" {
  description = "Private Networks used by EKS Cluster"
  type        = list(any)
  default     = ["10.1.0.0/17", "10.1.128.0/24"]
}

variable "vpc_public_subnets" {
  description = "Public Networks used by EKS Cluster"
  type        = list(any)
  default     = ["10.1.129.0/24", "10.1.130.0/24"]
}

variable "eks_instance_types" {
  description = "List of AWS Node types available to EKS Cluster"
  type        = list(any)
  default     = ["t3a.xlarge", "t3a.large"]
}

variable "eks_instance_type" {
  description = "AWS Node type for user pod nodes"
  default     = "t3a.large"
}

variable "cluster_base_name" {
  description = "Base/Prefix Name of EKS Cluster"
  default     = "jupyterhub"
}

variable "cluster_name_random" {
  description = "Enable/Disable Random String in Cluster Name (1/0)"
  default     = "1"
}

variable "wg_min_size" {
  description = "Minimum size for worker node"
  default     = "0"
}

variable "wg_max_size" {
  description = "Maximum size for worker node"
  default     = "2"
}

variable "wg_desired_cap" {
  description = "Desired capacity for worker node"
  default     = "0"
}

variable "ug_min_size" {
  description = "Minimum size for user node"
  default     = "0"
}

variable "ug_max_size" {
  description = "Maximum size for user node"
  default     = "2"
}

variable "ug_desired_cap" {
  description = "Desired capacity for user node"
  default     = "0"
}

variable "kube_version" {
  description = "Desired Kubernetes version for Cluster and Nodes."
  default     = "1.23"
}

variable "tag_project_name" {
  description = "Project Name Tag"
  default     = "jupyterhub"
}

variable "environment" {
  description = "Environment Name"
  default     = "dev"
}

variable "tag_department" {
  description = "Department Tag"
  default     = "Department"
}

variable "tag_dept_service" {
  description = "Service Tag"
  default     = "Jupyterhub"
}

variable "enable_autoscaler" {
  description = "Enable/Disable cluster autoscale"
  default     = true
}

variable "enable_kubecost" {
  description = "Enable/Disable kubecost"
  default     = false
}

variable "enable_metricsserver" {
  description = "Enable/Disable metrics server"
  default     = true
}

variable "enable_certmanager" {
  description = "Enable/Disable cert manager"
  default     = false
}

variable "fluentbit_group" {
  description = "fluent bit cloudwatch log group"
  default     = "/aws/eks/fluentbit-cloudwatch/jupyter/logs"

}

variable "fluentbit_stream_name" {
  description = "fluent bit cloudwatch log stream"
  default     = "fluentbit-jupyter"
}

variable "sns_name" {
  description = "name of the sns topic"
  default     = "jupyter-alerts"

}

variable "webhook_url" {
  description = "webook url of slack"
  default     = "SLACK_URL"
}


variable "alerts_enabled" {
  description = "variable to control if alerts are enabled or disabled"
  default     = true
}

variable "fluent_bit_enabled" {
  description = "variable to control if alerts are enabled or disabled"
  default     = true
}

variable "dashboard_enabled" {
  description = "variable to control if alerts are enabled or disabled"
  default     = true
}

variable "cluster_name" {
  description = "cluster name for cloudwatch alerts"
  default     = "CLUSTER_NAME"
}

variable "namespace" {
  default = "ContainerInsights"
}

variable "dashboard_name" {
  type    = string
  default = "CLUSTER_NAME"
}

variable "observability_namespace" {
  default = "amazon-cloudwatch"

}

variable "velero_namespace" {
  default = "velero"
}

variable "velero_enabled" {
  description = "variable to control if velero tool is enabled or disabled"
  default = true
}

variable "velero_bucket_name" {
  default = "velero-jupyterhub"
}

variable "kube2iam_namespace" {
  default = "kube2iam"
}

variable "kube2iam_enabled" {
  description = "variable to control if kube2iam tool is enabled or disabled"
  default = false
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry"
  default = true
}

variable "enable_dhcp_options" {
  description = "Should be true if you want to specify a DHCP options set with a custom domain name, DNS servers, NTP servers, netbios servers, and/or netbios server type"
  type        = bool
  default     = true
}

variable "dhcp_options_domain_name" {
  description = "Specifies DNS name for DHCP options set (requires enable_dhcp_options set to true)"
  type        = string
  default     = ""
}

variable "dhcp_options_domain_name_servers" {
  description = "Specify a list of DNS server addresses for DHCP options set, default to AWS provided (requires enable_dhcp_options set to true)"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "aws_load_balancer_controller_chart_version" {
  description = "The chart version of the aws load balancer controller"
  default = "1.4.7"
}

variable "cluster_autoscaler_chart_version" {
  description = "The chart version of the cluster autoscaler"
  default = "9.21.1"
}
