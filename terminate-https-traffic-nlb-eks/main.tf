provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

// If domain IS managed by Route53
data "aws_route53_zone" "selected" {
  name         = "${var.domain_name}."
  private_zone = false
}

resource "aws_route53_record" "acm_verification" {
  zone_id = data.aws_route53_zone.selected.zone_id
  type    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_type
  name    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_name
  ttl     = "300"
  records = [aws_acm_certificate.cert.domain_validation_options[0].resource_record_value]
}

// This resource doesn't create anything
// it just waits for the certificate to be created, and validation to succeed, before being created
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.acm_verification.fqdn]
}

// If domain is NOT managed by Route53
# output "domain_validation_options" {
#   description = "If your domain isn't managed by Route 53, manually finish the ACM creation by creating these DNS records in your registar service"
#   value       = aws_acm_certificate.cert.domain_validation_options
# }

output "acm_certificate_arn" {
  description = "ARN of the ACM Certificate"
  value       = aws_acm_certificate.cert.arn
}

