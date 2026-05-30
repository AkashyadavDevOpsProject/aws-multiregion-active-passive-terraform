variable "project" {
  description = "Project name prefix"
  type        = string
  default     = "swat"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod-dr"
}

variable "region" {
  description = "DR AWS region"
  type        = string
  default     = "ap-south-2"
}

variable "vpc_cidr" {
  description = "DR VPC CIDR block"
  type        = string
}

variable "availability_zones" {
  description = "AZs to deploy subnets into in the DR region"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets — one per AZ"
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private app subnets — one per AZ"
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private DB subnets — one per AZ"
  type        = list(string)
}

variable "hosted_zone_name" {
  description = "Route 53 hosted zone name (e.g., example.com)"
  type        = string
}

variable "domain_name" {
  description = "Application domain name (e.g., app.example.com)"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional SANs for the ACM certificate"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID — passed from primary environment output or looked up manually"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "eks_cluster_role_arn" {
  description = "EKS cluster IAM role ARN — from primary environment iam module output"
  type        = string
}

variable "eks_node_group_role_arn" {
  description = "EKS node group IAM role ARN — from primary environment iam module output"
  type        = string
}

variable "devops_ec2_instance_profile_name" {
  description = "DevOps EC2 instance profile name — from primary environment iam module output"
  type        = string
}

variable "devops_ec2_instance_type" {
  description = "EC2 instance type for the DevOps instance"
  type        = string
  default     = "t3.medium"
}

variable "eks_node_groups" {
  description = "Map of EKS managed node group configurations"
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
  description = "Explicit version pins for EKS managed add-ons"
  type = object({
    coredns    = string
    kube_proxy = string
    vpc_cni    = string
    ebs_csi    = string
    efs_csi    = string
  })
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.r6g.medium"
}

variable "redis_num_nodes" {
  description = "Number of Redis cache nodes (1 = no HA for warm standby)"
  type        = number
  default     = 1
}

variable "efs_access_points" {
  description = "Map of EFS Access Point configurations"
  type = map(object({
    path        = string
    uid         = number
    gid         = number
    permissions = string
  }))
  default = {}
}

variable "alb_target_groups" {
  description = "Map of ALB target group configurations"
  type = map(object({
    port              = number
    health_check_path = string
  }))
  default = {}
}

variable "alb_listener_rules" {
  description = "Map of ALB HTTPS listener rules (path-based routing)"
  type = map(object({
    priority         = number
    target_group_key = string
    path_patterns    = list(string)
  }))
  default = {}
}

variable "cloudfront_origin_verify_secret" {
  description = "Secret value for X-Origin-Verify header — set via TF_VAR_cloudfront_origin_verify_secret"
  type        = string
  sensitive   = true
}

variable "s3_replication_role_arn" {
  description = "S3 CRR replication role ARN — from primary environment iam module output"
  type        = string
}

variable "alarm_email_endpoints" {
  description = "Email addresses to subscribe to the alarms SNS topic"
  type        = list(string)
  default     = []
}
