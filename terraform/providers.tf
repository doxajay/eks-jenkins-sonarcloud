#########################################################
# PROVIDERS CONFIGURATION
# Stable for AWS, Kubernetes, Template, and Terraform Cloud
#########################################################

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.63.0" # ✅ use a stable and current AWS provider
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31.0"
    }

    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
  }

  cloud {
    organization = "YOUR_ORG_NAME"      # 🔁 Replace with your Terraform Cloud org
    workspaces {
      name = "YOUR_WORKSPACE_NAME"      # 🔁 Replace with your Terraform Cloud workspace
    }
  }
}

#########################################################
# AWS PROVIDER
#########################################################
provider "aws" {
  region                      = var.region
  skip_metadata_api_check      = true
  skip_credentials_validation  = true
  skip_requesting_account_id   = true   # ✅ prevents “unsupported attribute account_id” bug
}

#########################################################
# EKS CLUSTER DATA SOURCES
# Used to configure Kubernetes provider below
#########################################################
data "aws_eks_cluster" "this" {
  name = "${var.project_name}-eks"

  depends_on = [
    aws_eks_cluster.main
  ]
}

data "aws_eks_cluster_auth" "this" {
  name = data.aws_eks_cluster.this.name

  depends_on = [
    aws_eks_cluster.main
  ]
}

#########################################################
# KUBERNETES PROVIDER (connects to EKS)
#########################################################
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token

  experiments {
    manifest_resource = true
  }
}
