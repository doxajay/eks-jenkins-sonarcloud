terraform {
  required_version = ">= 1.3.0"

  cloud {
    organization = "POV-1"
    workspaces { name = "eks-jenkins-sonarcloud" }
  }

  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.50" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.31" }
    template = { source = "hashicorp/template", version = "~> 2.2" }
  }
}

provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "this" {
  name = "${var.project_name}-eks"
}

data "aws_eks_cluster_auth" "this" {
  name = data.aws_eks_cluster.this.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}
