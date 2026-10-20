
 resource "aws_route53_zone" "main" {
   name = var.domain_name

   tags = {
     Name        = "${var.project_name}-${var.env}-zone"
     Environment = var.env
     Project     = var.project_name
   }
 }

 resource "aws_acm_certificate" "main" {
   domain_name               = var.domain_name
   subject_alternative_names = ["*.${var.domain_name}"]
   validation_method         = "DNS"

   lifecycle {
     create_before_destroy = true
   }

   tags = {
     Name        = "${var.project_name}-${var.env}-certificate"
     Environment = var.env
     Project     = var.project_name
   }
 }

 resource "aws_route53_record" "acm_validation" {
   for_each = {
     for dvo in aws_acm_certificate.main.domain_validation_options :
     dvo.domain_name => {
       name   = dvo.resource_record_name
       type   = dvo.resource_record_type
       record = dvo.resource_record_value
     }
   }

   zone_id         = aws_route53_zone.main.zone_id
   name            = each.value.name
   type            = each.value.type
   ttl             = 60
   records         = [each.value.record]
   allow_overwrite = true
 }

 resource "aws_acm_certificate_validation" "main" {
   certificate_arn = aws_acm_certificate.main.arn

   validation_record_fqdns = [
     for record in aws_route53_record.acm_validation : record.fqdn
   ]
 }


eksctl create iamserviceaccount `
    --cluster=eks-mp `
    --namespace=kube-system `
    --name=aws-load-balancer-controller `
    --attach-policy-arn=arn:aws:iam::216482850616:policy/AWSLoadBalancerControllerIAMPolicy `
    --override-existing-serviceaccounts `
    --region us-east-1 `
    --approve

   aws iam list-roles `
  --query "Roles[?contains(RoleName, 'aws-load-balancer-controller') || contains(RoleName, 'LoadBalancerController')].RoleName" `
  --output table
