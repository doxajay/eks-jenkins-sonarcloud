#########################################################
# PROVIDERS CONFIGURATION
# Stable for AWS, Kubernetes, Template, and Terraform Cloud
#########################################################

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.57.0"
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

  cloud {
    organization = "YOUR_ORG_NAME" # 🔁 Replace with your TFC org name
    workspaces {
      name = "YOUR_WORKSPACE_NAME" # 🔁 Replace with your Terraform Cloud workspace name
    }
  }
}

#########################################################
# AWS PROVIDER
#########################################################
provider "aws" {
  region                  = var.region
  skip_metadata_api_check = true
  skip_region_validation  = true
}

#########################################################
# EKS CLUSTER DATA SOURCES
# Used to configure Kubernetes provider below
#########################################################
data "aws_eks_cluster" "this" {
  name = "${var.project_name}-eks"
}

data "aws_eks_cluster_auth" "this" {
  name = data.aws_eks_cluster.this.name
}

#########################################################
# KUBERNETES PROVIDER (connects to EKS)
#########################################################
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

