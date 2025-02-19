variable "project" {
  description = "Project name prefix"
  type        = string
  default     = "swat"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "Primary AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "dr_region" {
  description = "DR AWS region"
  type        = string
  default     = "ap-south-2"
}

# -----------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------
variable "vpc_cidr" {
  description = "Primary VPC CIDR"
  type        = string
}

variable "availability_zones" {
  description = "AZs in primary region"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_app_subnet_cidrs" {
  type = list(string)
}

variable "private_db_subnet_cidrs" {
  type = list(string)
}

variable "dr_vpc_cidr" {
  description = "DR VPC CIDR"
  type        = string
}

variable "dr_availability_zones" {
  type = list(string)
}

variable "dr_public_subnet_cidrs" {
  type = list(string)
}

variable "dr_private_app_subnet_cidrs" {
  type = list(string)
}

variable "dr_private_db_subnet_cidrs" {
  type = list(string)
}

# -----------------------------------------------------------------------
# DNS / ACM
# -----------------------------------------------------------------------
variable "hosted_zone_name" {
  description = "Route 53 hosted zone (e.g., example.com)"
  type        = string
}

variable "domain_name" {
  description = "Application domain (e.g., app.example.com)"
  type        = string
}

variable "subject_alternative_names" {
  type    = list(string)
  default = []
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID — obtain via: aws route53 list-hosted-zones-by-name --dns-name <hosted_zone_name>"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------
# IAM / GitHub
# -----------------------------------------------------------------------
variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "terraform_state_bucket" {
  type    = string
  default = "terformstatefile2026-077154311968-ap-south-1-an"
}

variable "terraform_lock_table" {
  type    = string
  default = "terraform-state-lock"
}

# -----------------------------------------------------------------------
# EKS
# -----------------------------------------------------------------------
variable "kubernetes_version" {
  type    = string
  default = "1.32"
}

variable "eks_node_groups" {
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size_gb   = number
    labels         = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
}

variable "eks_addon_versions" {
  type = object({
    coredns    = string
    kube_proxy = string
    vpc_cni    = string
    ebs_csi    = string
    efs_csi    = string
  })
}

# -----------------------------------------------------------------------
# DevOps EC2
# -----------------------------------------------------------------------
variable "devops_ec2_instance_type" {
  type    = string
  default = "t3.medium"
}

# -----------------------------------------------------------------------
# Aurora
# -----------------------------------------------------------------------
variable "aurora_database_name" {
  type = string
}

variable "aurora_engine_version" {
  type    = string
  default = "16.2"
}

variable "aurora_primary_instance_count" {
  type    = number
  default = 2
}

variable "aurora_primary_instance_class" {
  type    = string
  default = "db.r6g.large"
}

variable "aurora_dr_instance_count" {
  type    = number
  default = 1
}

variable "aurora_dr_instance_class" {
  type    = string
  default = "db.r6g.medium"
}

variable "aurora_backup_retention_days" {
  type    = number
  default = 7
}

# -----------------------------------------------------------------------
# ElastiCache
# -----------------------------------------------------------------------
variable "redis_node_type" {
  type    = string
  default = "cache.r6g.large"
}

variable "redis_num_nodes" {
  type    = number
  default = 2
}

# -----------------------------------------------------------------------
# Amazon MQ
# -----------------------------------------------------------------------
variable "mq_admin_secret_id" {
  description = "Secrets Manager secret ID for MQ admin credentials"
  type        = string
}

# -----------------------------------------------------------------------
# EFS
# -----------------------------------------------------------------------
variable "efs_access_points" {
  type = map(object({
    path        = string
    uid         = number
    gid         = number
    permissions = string
  }))
  default = {}
}

# -----------------------------------------------------------------------
# Load Balancer
# -----------------------------------------------------------------------
variable "alb_target_groups" {
  type = map(object({
    port              = number
    health_check_path = string
  }))
  default = {}
}

variable "alb_listener_rules" {
  type = map(object({
    priority         = number
    target_group_key = string
    path_patterns    = list(string)
  }))
  default = {}
}

# -----------------------------------------------------------------------
# CloudFront
# -----------------------------------------------------------------------
variable "cloudfront_origin_verify_secret" {
  description = "Secret value for X-Origin-Verify header — never put the actual value here"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------
# Route 53 — DR values (from DR state or manual)
# -----------------------------------------------------------------------
variable "dr_nlb_dns_name" {
  description = "NLB DNS name in DR region — obtained after DR environment is applied"
  type        = string
  default     = ""
}

variable "dr_cloudfront_domain_name" {
  description = "CloudFront domain name in DR region"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------
# Observability
# -----------------------------------------------------------------------
variable "alarm_email_endpoints" {
  type    = list(string)
  default = []
}
