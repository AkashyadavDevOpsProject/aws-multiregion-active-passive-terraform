variable "project" { type = string }
variable "environment" { type = string }

variable "nlb_dns_name" {
  description = "DNS name of the public NLB — CloudFront origin"
  type        = string
}

variable "domain_aliases" {
  description = "Custom domain aliases for the CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "cloudfront_certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront (from acm module)"
  type        = string
}

variable "origin_verify_secret" {
  description = "Secret value set as X-Origin-Verify header — NLB/ALB SG validates this to block direct access"
  type        = string
  sensitive   = true
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_All"
}

variable "waf_rate_limit" {
  description = "Maximum requests per 5 minutes per IP before WAF blocks"
  type        = number
  default     = 2000
}

variable "geo_restriction_type" {
  description = "CloudFront geo restriction type (none, whitelist, blacklist)"
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "List of country codes for geo restriction"
  type        = list(string)
  default     = []
}

variable "access_logs_bucket" {
  description = "S3 bucket name (without .s3.amazonaws.com) for CloudFront access logs"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
