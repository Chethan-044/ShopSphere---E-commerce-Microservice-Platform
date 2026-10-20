locals {
  ecr_repositories = toset([
    "ecommerce-frontend",
    "ecommerce-user-service",
    "ecommerce-product-service",
    "ecommerce-order-service",
    "ecommerce-storage-service"
  ])
}

resource "aws_ecr_repository" "microservices" {
  for_each = local.ecr_repositories

  name                 = each.value
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

output "ecr_repository_urls" {
  description = "ECR repository URLs for ecommerce microservices"

  value = {
    for name, repository in aws_ecr_repository.microservices :
    name => repository.repository_url
  }
}