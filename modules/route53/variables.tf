variable "project" { type = string }
variable "environment" { type = string }

variable "hosted_zone_name" {
  description = "Route 53 hosted zone name (e.g., example.com)"
  type        = string
}

variable "domain_name" {
  description = "Full domain name for the application (e.g., app.example.com)"
  type        = string
}

variable "health_check_path" {
  description = "Path used for Route 53 health checks"
  type        = string
  default     = "/health"
}

variable "primary_nlb_dns_name" {
  description = "DNS name of the primary region NLB — used for health check FQDN"
  type        = string
}

variable "dr_nlb_dns_name" {
  description = "DNS name of the DR region NLB — used for DR health check FQDN"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "Primary CloudFront distribution domain name (from cloudfront module)"
  type        = string
}

variable "dr_cloudfront_domain_name" {
  description = "DR CloudFront distribution domain name"
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "Route 53 hosted zone ID for CloudFront alias records (always Z2FDTNDATAQYW2)"
  type        = string
  default     = "Z2FDTNDATAQYW2"
}

variable "tags" {
  type    = map(string)
  default = {}
}
