variable "project" { type = string }
variable "environment" { type = string }

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for NLB placement"
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "Private app subnet IDs for ALB placement"
  type        = list(string)
}

variable "nlb_sg_id" {
  description = "Security group ID for the public NLB"
  type        = string
}

variable "alb_sg_id" {
  description = "Security group ID for the private ALB"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the ALB HTTPS listener (primary region cert)"
  type        = string
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB/NLB access logs"
  type        = string
}

variable "enable_access_logs" {
  description = "Enable access logging to S3"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the load balancers"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Health check path for the NLB → ALB target group"
  type        = string
  default     = "/health"
}

variable "target_groups" {
  description = "Map of ALB target group configurations keyed by short service name"
  type = map(object({
    port              = number
    health_check_path = string
  }))
  default = {}
}

variable "listener_rules" {
  description = "Map of ALB HTTPS listener rules (path-based routing)"
  type = map(object({
    priority         = number
    target_group_key = string
    path_patterns    = list(string)
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
