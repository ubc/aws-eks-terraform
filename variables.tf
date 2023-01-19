variable "region" {
  default = "ca-central-1"
}

variable "profile" {
  description = "AWS profile to use for authentication"
  default     = "urn:amazon:webservices"
}

variable "vpc_cidr" {
  description = "AWS VPC CIDR"
  default = "10.1.0.0/16"
}

variable "eks_node_disk_size" {
  description = "AWS EKS Node disk size in GB"
  default = "72"
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
  default = ["m5.xlarge", "m5n.xlarge", "m5n.large", "m5.large"]
}

variable "eks_instance_type" {
  description = "AWS Node type for user pod nodes"
  default     = "m5.xlarge"
}

variable "cluster_base_name" {
  description = "Base/Prefix Name of EKS Cluster"
  default     = "UBC-EKS"
}

variable "cluster_name_random" {
  description = "Enable/Disable Random String in Cluster Name (1/0)"
  default     = "1"
}

variable "wg_min_size" {
  description = "Minimum size for Worker node"
  default     = "0"
}

variable "wg_max_size" {
  description = "Maximum size for Worker node"
  default     = "2"
}

variable "wg_desired_cap" {
  description = "Desired capacity for Worker node"
  default     = "0"
}

variable "ug_min_size" {
  description = "Minimum size for Worker node"
  default     = "0"
}

variable "ug_max_size" {
  description = "Maximum size for Worker node"
  default     = "5"
}

variable "ug_desired_cap" {
  description = "Desired capacity for Worker node"
  default     = "0"
}

variable "kube_version" {
  description = "Desired Kubernetes version for Cluster and Nodes."
  default     = "1.22"
}

variable "tag_project_name" {
  description = "Project Name Tag"
  default     = "Project Name"
}

variable "environment" {
  description = "Environment Name"
  default     = "dev"
}

variable "tag_department" {
  description = "Department Tag"
  default     = "Department Name"
}

variable "tag_dept_service" {
  description = "Service Tag"
  default     = "Service Name"
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
