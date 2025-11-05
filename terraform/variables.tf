# Core variables
variable "project_name" {
  type        = string
  description = "Short prefix for tagging all resources"
  default     = "eksjenkins"
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-west-2"
}

variable "cluster_version" {
  type        = string
  description = "EKS version"
  default     = "1.29"
}
