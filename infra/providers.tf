terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  cloud {
    organization = "cloudgenius-acme"
    workspaces {
      name = "cicd-jenkins-terraform-and-aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
