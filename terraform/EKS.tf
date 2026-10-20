resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = [
      aws_subnet.private[0].id,
      aws_subnet.private[1].id
  ]

    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access

    security_group_ids = [
      aws_security_group.eks-cluster-sg.id
    ]
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = {
    Name        = var.cluster_name
    Environment = var.env
      "karpenter.sh/discovery"    = "eks-mp"

  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# EKS cluster add-ons
resource "aws_eks_addon" "addons" {
  for_each = {
    for addon in var.addons : addon.name => addon
  }

  cluster_name  = aws_eks_cluster.eks.name
  addon_name    = each.value.name
  addon_version = each.value.version

  depends_on = [
    aws_eks_cluster.eks
  ]
}

# Obtain the OIDC issuer certificate
data "tls_certificate" "eks_certificate" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

# Register the EKS OIDC provider with IAM
resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.eks_certificate.certificates[0].sha1_fingerprint
  ]
}

resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = aws_eks_cluster.eks.name
  principal_arn = aws_iam_role.karpenter_node_role.arn
  type          = "EC2_LINUX"
}


//nodes

resource "aws_iam_role" "bootstrap_node" {
  name = "${var.cluster_name}-bootstrap-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-bootstrap-node-role"
    Environment = var.env
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "bootstrap_worker" {
  role       = aws_iam_role.bootstrap_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "bootstrap_cni" {
  role       = aws_iam_role.bootstrap_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "bootstrap_ecr" {
  role       = aws_iam_role.bootstrap_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}



resource "aws_eks_node_group" "bootstrap" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.cluster_name}-bootstrap"
  node_role_arn   = aws_iam_role.bootstrap_node.arn
  subnet_ids      = aws_subnet.private[*].id

  instance_types = ["t3.small"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_eks_addon.addons,
    aws_iam_role_policy_attachment.bootstrap_worker,
    aws_iam_role_policy_attachment.bootstrap_cni,
    aws_iam_role_policy_attachment.bootstrap_ecr
  ]

  tags = {
    Name        = "${var.cluster_name}-bootstrap"
    Environment = var.env
    Project     = var.project_name
  }
}