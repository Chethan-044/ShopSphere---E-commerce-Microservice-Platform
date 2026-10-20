

output "vpc_id" {
  description = "ID of the main VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the main VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}
output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  description = "EKS Kubernetes API endpoint"
  value       = aws_eks_cluster.eks.endpoint
}

output "cluster_oidc_issuer" {
  description = "EKS OIDC issuer URL"
  value       = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

output "karpenter_node_role_arn" {
  description = "IAM role used by Karpenter-provisioned EC2 nodes"
  value       = aws_iam_role.karpenter_node_role.arn
}

output "karpenter_controller_role_arn" {
  description = "IAM role used by the Karpenter controller"
  value       = aws_iam_role.karpenter_controller.arn
}