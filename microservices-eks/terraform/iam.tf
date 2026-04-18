################################################################################
# IAM roles used by the EKS control plane and the managed node group
################################################################################

# --- EKS cluster role -------------------------------------------------------

data "aws_iam_policy_document" "eks_cluster_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# --- EKS node group role ----------------------------------------------------

data "aws_iam_policy_document" "eks_node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_node" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume.json
  tags               = local.common_tags
}

# Standard AWS-managed policies required by EKS worker nodes, plus ECR pull
# access so our pods can pull from the private ECR repos created here.
locals {
  node_managed_policies = {
    worker = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    cni    = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    ecr    = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    ssm    = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_policies" {
  for_each   = local.node_managed_policies
  role       = aws_iam_role.eks_node.name
  policy_arn = each.value
}
