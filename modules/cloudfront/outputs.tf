output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.main.arn
}

output "domain_name" {
  description = "CloudFront distribution domain name (*.cloudfront.net) — used in Route 53 alias records"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID for CloudFront — use in alias records (Z2FDTNDATAQYW2)"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF WebACL attached to this distribution"
  value       = aws_wafv2_web_acl.cloudfront.arn
}
