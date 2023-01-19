variable "region" {
  default = "ca-central-1"
}

variable "profile" {
  description = "AWS profile to use for authentication"
  default     = "default"
}

variable "vpc_cidr" {
  description = "AWS VPC CIDR"
  default = "10.1.0.0/16"
}

variable "eks_node_disk_size" {
  description = "AWS EKS Node disk size in GB"
  default = "64"
}

variable "eks_rds_db" {
  description = "Create RDS MySQL Database"
  default = "0"
}

variable "vpc_private_subnets" {
  description = "Private Networks used by EKS Cluster"
  type    = list
  default = ["10.1.0.0/17", "10.1.128.0/24"]
}

variable "vpc_public_subnets" {
  description = "Public Networks used by EKS Cluster"
  type    = list
  default = ["10.1.129.0/24", "10.1.130.0/24"]
}

variable "eks_instance_types" {
  description = "List of AWS Node types available to EKS Cluster"
  type    = list
  default = ["t3a.xlarge", "t3a.large"]
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
  default     = "1.22"
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
