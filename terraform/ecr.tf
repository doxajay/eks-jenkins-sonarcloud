#########################################################
# Elastic Container Registry (ECR) for Jenkins Pipeline #
#########################################################

resource "aws_ecr_repository" "acme_app_repo" {
  name = "acme-app-repo"

  # Automatically scan images for vulnerabilities
  image_scanning_configuration {
    scan_on_push = true
  }

  # Encrypt all images at rest
  encryption_configuration {
    encryption_type = "AES256"
  }

  # Enable immutable image tags to prevent overwrites
  image_tag_mutability = "IMMUTABLE"

  # Prevent accidental deletion (safe)
  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Project     = "EKS-Jenkins"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

#########################################################
# Output repository URL for Jenkins pipeline use        #
#########################################################

output "ecr_repository_url" {
  description = "The full ECR repository URL used for Docker push"
  value       = aws_ecr_repository.acme_app_repo.repository_url
}
