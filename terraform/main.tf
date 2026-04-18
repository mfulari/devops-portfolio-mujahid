data "aws_caller_identity" "current" {}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }

  # All subnets the cluster should see. Public subnets are only included
  # when provided so public LoadBalancers can be created for the demo.
  cluster_subnet_ids = distinct(concat(var.private_subnet_ids, var.public_subnet_ids))
}
