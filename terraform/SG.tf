// Security Group for EKS Cluster
resource "aws_security_group" "eks-cluster-sg" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for the EKS cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTPS access to the EKS API"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-cluster-sg"
    Environment = var.env
    Project     = var.project_name
      "karpenter.sh/discovery" = var.cluster_name

  }
}

