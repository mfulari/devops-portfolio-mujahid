output "aws_region" {
  description = "AWS region the cluster was created in."
  value       = var.aws_region
}

output "cluster_name" {
  description = "Name of the EKS cluster (use with aws eks update-kubeconfig)."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer" {
  description = "OIDC issuer URL of the EKS cluster (useful for IRSA)."
  value       = module.eks.cluster_oidc_issuer_url
}

output "ecr_repository_urls" {
  description = "Map of service name -> ECR repository URL for pushing images."
  value       = { for k, r in aws_ecr_repository.services : k => r.repository_url }
}

output "github_actions_role_arn" {
  description = "IAM role the GitHub Actions workflow should assume via OIDC."
  value       = aws_iam_role.github_actions_deployer.arn
}

output "kubeconfig_command" {
  description = "Convenience command to configure kubectl locally."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}
