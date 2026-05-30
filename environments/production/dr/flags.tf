# =======================================================================================================
# RESOURCE CREATION FLAGS — production/dr
# =======================================================================================================
# Control which modules to deploy or skip during Terraform apply.
# Set a flag to false to skip that module — useful for warm-standby cost reduction
# or incremental DR buildout.
#
# DEPENDENCY TIERS — deploy in this order:
#
#   Tier 1 — Foundation  : networking, s3
#   Tier 2 — Connectivity: security_groups
#   Tier 3 — Platform    : vpc_endpoints, acm, eks, elasticache, efs
#   Tier 4 — Compute     : devops_ec2, load_balancer
#   Tier 5 — Edge        : cloudfront
#   Tier 6 — Operations  : observability
#
# Note: IAM roles are created by the primary environment and passed as variables here.
# Note: Aurora DR secondary cluster is managed by the primary environment's aurora module.
# =======================================================================================================

variable "create" {
  description = "Feature flags — set each to false to skip deploying that module"
  type = object({
    // ----- Tier 1: Foundation — deploy first -----
    networking = bool // DR VPC in ap-south-2, 3-tier subnets, NAT GW, flow logs
    s3         = bool // S3 buckets in DR region (target for CRR from primary)

    // ----- Tier 2: Connectivity — requires Tier 1 -----
    security_groups = bool // All 9 SGs for DR VPC (requires: networking)

    // ----- Tier 3: Platform — requires Tier 2 -----
    vpc_endpoints = bool // 13 interface + S3/DynamoDB gateway endpoints (requires: networking, security_groups)
    acm           = bool // ACM cert: DR region + us-east-1 cert for CloudFront (requires: none — uses var.route53_zone_id)
    eks           = bool // EKS 1.34 cluster warm standby, reduced node count (requires: networking, security_groups)
    elasticache   = bool // ElastiCache Redis single-node warm standby (requires: networking, security_groups)
    efs           = bool // EFS Standard, mount targets, access points (requires: networking, security_groups)

    // ----- Tier 4: Compute — requires Tier 3 -----
    devops_ec2    = bool // DevOps EC2 warm standby, SSM-only access (requires: networking, security_groups, eks)
    load_balancer = bool // Public NLB → private ALB for DR traffic (requires: networking, security_groups, acm, s3)

    // ----- Tier 5: Edge — requires Tier 4 -----
    cloudfront = bool // CloudFront DR distribution + WAF (requires: load_balancer, acm, s3)

    // ----- Tier 6: Operations -----
    observability = bool // CloudWatch alarms, dashboard, SNS topic for DR region
  })

  default = {
    // Tier 1
    networking = true
    s3         = true
    // Tier 2
    security_groups = true
    // Tier 3
    vpc_endpoints = true
    acm           = true
    eks           = true
    elasticache   = true
    efs           = true
    // Tier 4
    devops_ec2    = true
    load_balancer = true
    // Tier 5
    cloudfront = true
    // Tier 6
    observability = true
  }

  # ----- Tier 2 dependency validations -----

  validation {
    condition     = !var.create.security_groups || var.create.networking
    error_message = "security_groups requires networking = true."
  }

  # ----- Tier 3 dependency validations -----

  validation {
    condition     = !var.create.vpc_endpoints || (var.create.networking && var.create.security_groups)
    error_message = "vpc_endpoints requires networking = true and security_groups = true."
  }

  validation {
    condition     = !var.create.eks || (var.create.networking && var.create.security_groups)
    error_message = "eks requires networking = true and security_groups = true."
  }

  validation {
    condition     = !var.create.elasticache || (var.create.networking && var.create.security_groups)
    error_message = "elasticache requires networking = true and security_groups = true."
  }

  validation {
    condition     = !var.create.efs || (var.create.networking && var.create.security_groups)
    error_message = "efs requires networking = true and security_groups = true."
  }

  # ----- Tier 4 dependency validations -----

  validation {
    condition     = !var.create.devops_ec2 || (var.create.networking && var.create.security_groups && var.create.eks)
    error_message = "devops_ec2 requires networking = true, security_groups = true, and eks = true."
  }

  validation {
    condition     = !var.create.load_balancer || (var.create.networking && var.create.security_groups && var.create.acm && var.create.s3)
    error_message = "load_balancer requires networking = true, security_groups = true, acm = true, and s3 = true."
  }

  # ----- Tier 5 dependency validations -----

  validation {
    condition     = !var.create.cloudfront || (var.create.load_balancer && var.create.acm && var.create.s3)
    error_message = "cloudfront requires load_balancer = true, acm = true, and s3 = true."
  }
}
