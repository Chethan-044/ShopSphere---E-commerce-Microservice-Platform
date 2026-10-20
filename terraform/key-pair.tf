
resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  key_name   = "${var.cluster_name}-bastion-key"
  public_key = tls_private_key.bastion.public_key_openssh

  tags = {
    Name        = "${var.cluster_name}-bastion-key"
    Environment = var.env
    Project     = var.project_name
  }
}

resource "local_sensitive_file" "bastion_private_key" {
  content         = tls_private_key.bastion.private_key_pem
  filename        = "${path.module}/${var.cluster_name}-bastion-key.pem"
  file_permission = "0600"
}
