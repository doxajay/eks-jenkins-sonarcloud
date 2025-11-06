# =====================================================
# Elastic Container Registry (ECR)
# =====================================================

resource "aws_ecr_repository" "acme_app_repo" {
  name = "acme-app-repo"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_tag_mutability = "IMMUTABLE"

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

output "ecr_repository_url" {
  description = "Full ECR repo URL for Jenkins pipeline"
  value       = aws_ecr_repository.acme_app_repo.repository_url
}
