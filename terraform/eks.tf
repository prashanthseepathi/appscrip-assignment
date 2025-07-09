##############################
# EKS Cluster
##############################

resource "aws_eks_cluster" "eks_cluster" {
  name     = "eks-cluster-appscrip"
  version  = "1.32"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name = "eks-cluster-appscrip"
  }
}

##############################
# EKS Fargate Profile
##############################

resource "aws_eks_fargate_profile" "fargate_profile" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "appscrip"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  selector {
    namespace = "default"
  }
  selector {
    namespace = "kube-system"
  }
  selector {
    namespace = "argocd"
  }


  depends_on = [
    aws_iam_role_policy_attachment.fargate_execution_attach,
    aws_eks_cluster.eks_cluster
  ]

  tags = {
    Name = "eks-fargate-profile"
  }
}

##############################
# EKS Add-ons
##############################

resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  addon_name    = "coredns"
  addon_version = "v1.11.1-eksbuild.4"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name     = aws_eks_cluster.eks_cluster.name
  addon_name       = "kube-proxy"
  addon_version    = "v1.29.0-eksbuild.1"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name     = aws_eks_cluster.eks_cluster.name
  addon_name       = "vpc-cni"
  addon_version    = "v1.17.1-eksbuild.1"
}

