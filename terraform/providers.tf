# =====================================================
# Providers (AWS + Kubernetes wired to EKS)
# =====================================================
terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
  }
}

provider "aws" {
  region = var.region
}

# Data sources to discover the EKS API details after the cluster is created
data "aws_eks_cluster" "this" {
  name       = aws_eks_cluster.main.name
  depends_on = [aws_eks_cluster.main]
}

data "aws_eks_cluster_auth" "this" {
  name       = aws_eks_cluster.main.name
  depends_on = [aws_eks_cluster.main]
}

# IMPORTANT: this points Terraform's Kubernetes provider to your EKS API
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  token                  = data.aws_eks_cluster_auth.this.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
}
