# =======================================================================================================
# RESOURCE CREATION FLAGS — staging
# =======================================================================================================
# Control which modules to deploy or skip during Terraform apply.
# Set a flag to false to skip that module — useful for cost reduction during
# off-hours or testing individual components.
#
# DEPENDENCY TIERS — deploy in this order:
#
#   Tier 1 — Foundation  : iam, networking, s3
#   Tier 2 — Connectivity: security_groups
#   Tier 3 — Platform    : vpc_endpoints, acm, eks, elasticache, efs
#   Tier 4 — Compute     : devops_ec2, load_balancer
#   Tier 5 — Edge        : cloudfront
#   Tier 6 — Operations  : observability
#
# Note: No Aurora (uses RDS or external DB in staging), no Amazon MQ, no Transit Gateway.
# =======================================================================================================

variable "create" {
  description = "Feature flags — set each to false to skip deploying that module"
  type = object({
    // ----- Tier 1: Foundation — deploy first -----
    iam        = bool // GitHub OIDC, EKS/node/EC2 roles, S3 replication role
    networking = bool // VPC, 3-tier subnets (2 AZs), NAT GW, route tables
    s3         = bool // App-assets, access-logs, tf-artifacts buckets

    // ----- Tier 2: Connectivity — requires Tier 1 -----
    security_groups = bool // All 9 SGs (requires: networking)

    // ----- Tier 3: Platform — requires Tier 2 -----
    vpc_endpoints = bool // Interface + gateway VPC endpoints (requires: networking, security_groups)
    acm           = bool // ACM cert: staging region + us-east-1 for CloudFront (requires: none)
    eks           = bool // EKS 1.34 cluster, SPOT node group (requires: iam, networking, security_groups)
    elasticache   = bool // ElastiCache Redis single-node (requires: networking, security_groups)
    efs           = bool // EFS Standard, mount targets (requires: networking, security_groups)

    // ----- Tier 4: Compute — requires Tier 3 -----
    devops_ec2    = bool // DevOps EC2, SSM-only access (requires: iam, networking, security_groups, eks)
    load_balancer = bool // Public NLB → private ALB (requires: networking, security_groups, acm, s3)

    // ----- Tier 5: Edge — requires Tier 4 -----
    cloudfront = bool // CloudFront + WAF WebACL (requires: load_balancer, acm, s3)

    // ----- Tier 6: Operations -----
    observability = bool // CloudWatch alarms, dashboard, SNS topic
  })

  default = {
    // Tier 1
    iam        = true
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
    condition     = !var.create.eks || (var.create.iam && var.create.networking && var.create.security_groups)
    error_message = "eks requires iam = true, networking = true, and security_groups = true."
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
    condition     = !var.create.devops_ec2 || (var.create.iam && var.create.networking && var.create.security_groups && var.create.eks)
    error_message = "devops_ec2 requires iam = true, networking = true, security_groups = true, and eks = true."
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
