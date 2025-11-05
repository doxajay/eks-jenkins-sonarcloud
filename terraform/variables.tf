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

# ===========================
# Jenkins Instance Variables
# ===========================

variable "jenkins_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "EC2 instance type for Jenkins server"
}

variable "jenkins_allowed_cidr_http" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR allowed to reach Jenkins UI (8080) — tighten later"
}

variable "jenkins_allowed_cidr_ssh" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR allowed to SSH into Jenkins instance — tighten later"
}

variable "jenkins_admin_username" {
  type        = string
  default     = "admin"
  description = "Initial Jenkins admin username"
}

variable "jenkins_admin_password" {
  type        = string
  sensitive   = true
  description = "Initial Jenkins admin password"
}

variable "create_jenkins_credentials" {
  type        = bool
  default     = true
  description = "Whether to auto-create SonarCloud and TFC credentials in Jenkins"
}

variable "sonarcloud_token" {
  type        = string
  sensitive   = true
  description = "SonarCloud API token used to register Jenkins credential"
}

variable "tfc_token" {
  type        = string
  sensitive   = true
  description = "Terraform Cloud user token used to register Jenkins credential"
}
