output "primary_bucket_arns" {
  description = "Map of bucket key => ARN for primary region buckets"
  value       = { for k, b in aws_s3_bucket.primary : k => b.arn }
}

output "primary_bucket_names" {
  description = "Map of bucket key => bucket name for primary region buckets"
  value       = { for k, b in aws_s3_bucket.primary : k => b.id }
}

output "dr_bucket_arns" {
  description = "Map of bucket key => ARN for DR region buckets"
  value       = { for k, b in aws_s3_bucket.dr : k => b.arn }
}

output "access_logs_bucket_name" {
  description = "Name of the access logs bucket — used by load-balancer and cloudfront modules"
  value       = aws_s3_bucket.primary["access_logs"].id
}

output "source_bucket_arns" {
  description = "All primary bucket ARNs — passed to iam module for CRR role scoping"
  value       = [for b in aws_s3_bucket.primary : b.arn]
}

output "destination_bucket_arns" {
  description = "All DR bucket ARNs — passed to iam module for CRR role scoping"
  value       = [for b in aws_s3_bucket.dr : b.arn]
}
