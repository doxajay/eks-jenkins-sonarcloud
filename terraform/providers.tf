#########################################################
# PROVIDERS CONFIGURATION
# Stable for AWS, Kubernetes, Template, and Terraform Cloud
#########################################################

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.65"  # ✅ safe version (avoid 5.66–5.69)
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }

    template = {
      source  = "hashicorp/template"
      version = "~> 2.2"
    }
  }
}

#########################################################
# AWS PROVIDER
#########################################################
provider "aws" {
  region = var.region
}

#########################################################
# EKS CLUSTER DATA (for Kubernetes provider connection)
#########################################################
data "aws_eks_cluster" "this" {
  name = "${var.project_name}-eks"
}

data "aws_eks_cluster_auth" "this" {
  name = data.aws_eks_cluster.this.name
}

#########################################################
# KUBERNETES PROVIDER (connected to EKS cluster)
#########################################################
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

#########################################################
# OPTIONAL: disable identity serialization for TF Cloud
# (workaround if errors persist)
#########################################################
# provider_meta "terraform" {
#   skip_resource_identity = true
# }
