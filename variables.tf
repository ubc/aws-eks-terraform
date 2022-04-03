variable "region" {
  default = "us-west-2"
}

variable "profile" {
  description = "AWS profile to use for authentication"
  default     = "urn:amazon:webservices"
}

variable "eks_node_type" {
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
