################################################################################
# ECR repositories for the two microservices
################################################################################

locals {
  service_names = ["patient-service", "appointment-service"]
}

# for_each over the service list keeps the two repos DRY.
resource "aws_ecr_repository" "services" {
  for_each = toset(local.service_names)

  name                 = "${var.project}/${each.value}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # demo convenience; flip to false for prod

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, {
    Service = each.value
  })
}

# Keep the repo tidy: retain only the last 20 images.
resource "aws_ecr_lifecycle_policy" "services" {
  for_each   = aws_ecr_repository.services
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retain last 20 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 20
        }
        action = {
          type = "expire"
        }
      },
    ]
  })
}
