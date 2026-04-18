data "aws_caller_identity" "current" {}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }

  # All subnets the cluster should see. Public subnets are only included when
  # provided so public LoadBalancers can be created for the demo.
  cluster_subnet_ids = distinct(concat(var.private_subnet_ids, var.public_subnet_ids))
}

################################################################################
# EKS cluster (reuses an existing VPC / subnets)
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  # Reuse the caller-provided VPC and subnets.
  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = local.cluster_subnet_ids

  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = true

  # Give the Terraform identity full admin so we can bootstrap workloads.
  enable_cluster_creator_admin_permissions = true

  # Grant additional roles (e.g. your SSO role) cluster-admin access so humans
  # can run kubectl after bootstrap.
  access_entries = {
    for idx, role_arn in var.cluster_admin_role_arns : "admin-${idx}" => {
      principal_arn = role_arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    eks-pod-identity-agent = {}
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Let worker nodes pull from our private ECR repos without extra setup.
      iam_role_additional_policies = {
        ECRReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
    }
  }

  tags = local.common_tags
}
