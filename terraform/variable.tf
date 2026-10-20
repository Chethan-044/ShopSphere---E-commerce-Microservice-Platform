
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "eks-mp"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks-mp"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.33"
}

variable "endpoint_private_access" {
  description = "Enable private EKS API access"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public EKS API access"
  type        = bool
  default     = true
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR ranges"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR ranges"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "domain_name" {
  description = "Project domain name"
  type        = string
}

variable "addons" {
  description = "EKS managed add-ons"
  type = list(object({
    name    = string
    version = optional(string)
  }))

  default = [
    { name = "vpc-cni" },
    { name = "kube-proxy" },
    { name = "coredns" },
    { name = "eks-pod-identity-agent" }
  ]
}




variable "bastion_instance_type" {
  description = "EC2 instance type for Bastion and Jenkins"
  type        = string
  default     = "t3.medium"
}

variable "bastion_volume_size" {
  description = "Bastion root disk size in GiB"
  type        = number
  default     = 30
}
