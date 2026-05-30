variable "project" {
  description = "Project name prefix for all resource names and tags"
  type        = string
}

variable "environment" {
  description = "Deployment environment (production, staging)"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name for ACM certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names to include in the certificate (SANs)"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID used for DNS validation CNAME records"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources in this module"
  type        = map(string)
  default     = {}
}
