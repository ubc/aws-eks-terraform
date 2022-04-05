variable "region" {
  default = "us-west-2"
}

variable "profile" {
  description = "AWS profile to use for authentication"
  default     = "urn:amazon:webservices"
}

variable "vpc_cidr" {
  description = "AWS VPC CIDR"
  default = "10.1.0.0/16"
}

variable "vpc_private_subnets" {
  description = "Private Networks used by EKS Cluster"
  type    = list
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "vpc_public_subnets" {
  description = "Public Networks used by EKS Cluster"
  type    = list
  default = ["10.1.101.0/24", "10.1.102.0/24"]
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

variable "ug_min_size" {
  description = "Minimum size for Uuser node"
  default     = "0"
}

variable "ug_max_size" {
  description = "Maximum size for User node"
  default     = "4"
}

variable "ug_desired_cap" {
  description = "Desired capacity for User node"
  default     = "0"
}

variable "wg_min_size" {
  description = "Minimum size for Worker node"
  default     = "0"
}

variable "wg_max_size" {
  description = "Maximum size for Worker node"
  default     = "4"
}

variable "wg_desired_cap" {
  description = "Desired capacity for Worker node"
  default     = "0"
}

variable "tag_project_name" {
  description = "Project Name Tag"
  default     = "Project Name"
}

variable "tag_enviroment_name" {
  description = "Enviroment Name Tag"
  default     = "UBC-Dev"
}
