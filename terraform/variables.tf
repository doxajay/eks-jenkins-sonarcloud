# --- Jenkins provisioning vars ---
variable "jenkins_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "EC2 type for Jenkins"
}

variable "jenkins_allowed_cidr_http" {
  type        = string
  default     = "0.0.0.0/0" # public for MVP; tighten later
  description = "CIDR allowed to reach Jenkins HTTP(8080)"
}

variable "jenkins_allowed_cidr_ssh" {
  type        = string
  default     = "0.0.0.0/0" # for MVP; change to your IP/CIDR
  description = "CIDR allowed to SSH (22) to Jenkins"
}

variable "jenkins_admin_username" {
  type        = string
  default     = "admin"
  description = "Initial Jenkins admin username"
}

variable "jenkins_admin_password" {
  type        = string
  sensitive   = true
  default     = "ChangeMe_123!"  # change in TFC workspace
  description = "Initial Jenkins admin password"
}

# Optional: if you want Jenkins to pre-create credentials non-interactively
variable "sonarcloud_token" {
  type        = string
  sensitive   = true
  default     = ""
  description = "SonarCloud token (optional) to auto-create Jenkins credential"
}

variable "tfc_token" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Terraform Cloud user token (optional) to auto-create Jenkins credential"
}

variable "create_jenkins_credentials" {
  type        = bool
  default     = true
  description = "If true, bootstrap will auto-create Jenkins credentials from vars"
}
