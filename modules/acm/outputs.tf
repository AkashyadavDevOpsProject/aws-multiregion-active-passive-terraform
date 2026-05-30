output "primary_certificate_arn" {
  description = "ARN of the ACM certificate issued in the primary region (ap-south-1) — used by ALB/NLB"
  value       = aws_acm_certificate_validation.primary.certificate_arn
}

output "cloudfront_certificate_arn" {
  description = "ARN of the ACM certificate issued in us-east-1 — required by CloudFront"
  value       = aws_acm_certificate_validation.cloudfront.certificate_arn
}

output "primary_domain_validation_options" {
  description = "Domain validation options for the primary certificate — useful for debugging DNS propagation"
  value       = aws_acm_certificate.primary.domain_validation_options
}
