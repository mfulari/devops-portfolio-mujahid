variable "aws_region" {
  type        = string
  description = "AWS region to deploy the EKS cluster and ECR repositories into."
  default     = "us-east-1"
}

variable "project" {
  type        = string
  description = "Short project name used for resource naming and tagging."
  default     = "hack-microservices"
}

variable "environment" {
  type        = string
  description = "Environment name used for tagging (e.g. dev, demo, prod)."
  default     = "demo"
}

variable "owner" {
  type        = string
  description = "Owner tag applied to all created resources."
  default     = "hackathon-team"
}

# --- Existing network (reused, not created by this stack) --------------------

variable "vpc_id" {
  type        = string
  description = "ID of the existing VPC where the EKS cluster will be created."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Existing private subnet IDs for EKS worker nodes (2+ AZs recommended)."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Existing public subnet IDs for the EKS control-plane ENIs / public LoadBalancers."
  default     = []
}

# --- EKS ---------------------------------------------------------------------

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster."
  default     = "hack-microservices-eks"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes minor version for the EKS control plane."
  default     = "1.30"
}

variable "node_instance_types" {
  type        = list(string)
  description = "EC2 instance types for the managed node group."
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  type        = number
  description = "Desired number of worker nodes."
  default     = 2
}

variable "node_min_size" {
  type        = number
  description = "Minimum number of worker nodes."
  default     = 1
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of worker nodes."
  default     = 3
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Whether the EKS API endpoint is publicly reachable (demo convenience)."
  default     = true
}

variable "cluster_admin_role_arns" {
  type        = list(string)
  description = "Additional IAM role ARNs granted cluster-admin access (e.g. your SSO role)."
  default     = []
}

# --- GitHub Actions OIDC -----------------------------------------------------

variable "github_org" {
  type        = string
  description = "GitHub organization / user that owns the repository (used for the OIDC trust)."
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name (without org) allowed to assume the deployer role."
}

variable "github_branches" {
  type        = list(string)
  description = "Branches allowed to assume the deployer role via OIDC."
  default     = ["main"]
}

variable "create_github_oidc_provider" {
  type        = bool
  description = "Create the token.actions.githubusercontent.com OIDC provider. Set to false if it already exists in the account."
  default     = true
}
