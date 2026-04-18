################################################################################
# GitHub Actions OIDC -> IAM role
#
# Lets the GitHub Actions workflow assume an AWS role with NO static keys.
# The role is scoped to this repo + the branches listed in var.github_branches.
################################################################################

data "tls_certificate" "github" {
  count = var.create_github_oidc_provider ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github[0].certificates[0].sha1_fingerprint]

  tags = local.common_tags
}

# Look up the existing provider when we're not creating one.
data "aws_iam_openid_connect_provider" "github_existing" {
  count = var.create_github_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  github_oidc_provider_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github_existing[0].arn

  github_subjects = [
    for branch in var.github_branches :
    "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"
  ]
}

data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_subjects
    }
  }
}

resource "aws_iam_role" "github_actions_deployer" {
  name               = "${var.project}-gha-deployer"
  description        = "Assumed by GitHub Actions to push images to ECR and deploy to EKS."
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
  tags               = local.common_tags
}

# ECR push/pull on our two repos only.
data "aws_iam_policy_document" "ecr_push" {
  statement {
    sid       = "ECRAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPushPullScopedRepos"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [for r in aws_ecr_repository.services : r.arn]
  }
}

resource "aws_iam_policy" "ecr_push" {
  name        = "${var.project}-gha-ecr-push"
  description = "Allow GitHub Actions to push images to the microservice ECR repos."
  policy      = data.aws_iam_policy_document.ecr_push.json
}

resource "aws_iam_role_policy_attachment" "gha_ecr_push" {
  role       = aws_iam_role.github_actions_deployer.name
  policy_arn = aws_iam_policy.ecr_push.arn
}

# Minimal EKS describe so `aws eks update-kubeconfig` works from the pipeline.
data "aws_iam_policy_document" "eks_describe" {
  statement {
    effect    = "Allow"
    actions   = ["eks:DescribeCluster", "eks:ListClusters"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_describe" {
  name        = "${var.project}-gha-eks-describe"
  description = "Allow GitHub Actions to run aws eks update-kubeconfig."
  policy      = data.aws_iam_policy_document.eks_describe.json
}

resource "aws_iam_role_policy_attachment" "gha_eks_describe" {
  role       = aws_iam_role.github_actions_deployer.name
  policy_arn = aws_iam_policy.eks_describe.arn
}

# Grant the deployer role cluster-admin via an EKS access entry so kubectl
# apply works over OIDC without touching aws-auth ConfigMap.
resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_iam_role.github_actions_deployer.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_actions_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_iam_role.github_actions_deployer.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.github_actions]
}
