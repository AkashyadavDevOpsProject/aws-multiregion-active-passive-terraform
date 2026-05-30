# =======================================================================================================
# RESOURCE CREATION FLAGS — production/primary
# =======================================================================================================
# Control which modules to deploy or skip during Terraform apply.
# Set a flag to false to skip that module — useful for incremental rollouts,
# targeted re-deployments, or cost management during testing.
#
# DEPENDENCY TIERS — deploy in this order to satisfy dependencies:
#
#   Tier 1 — Foundation   : iam, networking, networking_dr, s3
#   Tier 2 — Connectivity : transit_gateway, security_groups, security_groups_dr
#   Tier 3 — Platform     : vpc_endpoints, acm, eks, aurora, elasticache, amazon_mq, efs
#   Tier 4 — Compute      : devops_ec2, load_balancer
#   Tier 5 — Edge         : cloudfront, route53
#   Tier 6 — Operations   : observability, backup
#
# Validation blocks below enforce these rules at plan time.
# =======================================================================================================

variable "create" {
  description = "Feature flags — set each to false to skip deploying that module"
  type = object({
    // ----- Tier 1: Foundation — no module dependencies, deploy first -----
    iam           = bool // GitHub OIDC, EKS/node/EC2 roles, S3 CRR role, Backup role
    networking    = bool // Primary VPC, 3-tier subnets, NAT GW per AZ, flow logs
    networking_dr = bool // DR VPC in ap-south-2, identical 3-tier subnet layout
    s3            = bool // App-assets, access-logs, tf-artifacts + CRR to DR region

    // ----- Tier 2: Connectivity — requires Tier 1 -----
    transit_gateway    = bool // TGW pair + cross-region peering + route tables (requires: networking, networking_dr)
    security_groups    = bool // All 9 SGs in primary VPC — no circular deps (requires: networking)
    security_groups_dr = bool // All 9 SGs in DR VPC (requires: networking_dr)

    // ----- Tier 3: Platform — requires Tier 2 -----
    vpc_endpoints = bool // 13 interface + S3/DynamoDB gateway endpoints — primary VPC (requires: networking, security_groups)
    acm           = bool // ACM cert: primary region + us-east-1 cert for CloudFront (requires: none — uses var.route53_zone_id)
    eks           = bool // EKS 1.34 cluster, managed node groups, IRSA roles (requires: iam, networking, security_groups)
    aurora        = bool // Aurora Global DB: primary cluster + DR secondary cluster (requires: networking, networking_dr, security_groups, security_groups_dr)
    elasticache   = bool // ElastiCache Redis replication group, Multi-AZ, TLS, KMS (requires: networking, security_groups)
    amazon_mq     = bool // Amazon MQ ActiveMQ ACTIVE_STANDBY_MULTI_AZ (requires: networking, security_groups)
    efs           = bool // EFS Standard, mount targets per AZ, access points (requires: networking, security_groups)

    // ----- Tier 4: Compute — requires Tier 3 -----
    devops_ec2    = bool // DevOps EC2 ASG via SSM only, kubectl + helm pre-installed (requires: iam, networking, security_groups, eks)
    load_balancer = bool // Public NLB (target_type=alb) → private ALB + path-based routing (requires: networking, security_groups, acm, s3)

    // ----- Tier 5: Edge — requires Tier 4 -----
    cloudfront = bool // CloudFront distribution + WAF WebACL in us-east-1 (requires: load_balancer, acm, s3)
    route53    = bool // Active-passive failover records + Route 53 health checks (requires: load_balancer, cloudfront)

    // ----- Tier 6: Operations — requires Tier 3-5 -----
    observability = bool // CloudWatch alarms, dashboard, X-Ray group, SNS topic (requires: none — standalone)
    backup        = bool // AWS Backup vault + daily/weekly/monthly retention plans (requires: iam, aurora, efs, observability)
  })

  default = {
    // Tier 1
    iam           = true
    networking    = true
    networking_dr = true
    s3            = true
    // Tier 2
    transit_gateway    = true
    security_groups    = true
    security_groups_dr = true
    // Tier 3
    vpc_endpoints = true
    acm           = true
    eks           = true
    aurora        = true
    elasticache   = true
    amazon_mq     = true
    efs           = true
    // Tier 4
    devops_ec2    = true
    load_balancer = true
    // Tier 5
    cloudfront = true
    route53    = true
    // Tier 6
    observability = true
    backup        = true
  }

  # ----- Tier 2 dependency validations -----

  validation {
    condition     = !var.create.transit_gateway || (var.create.networking && var.create.networking_dr)
    error_message = "transit_gateway requires networking = true and networking_dr = true (deploy Tier 1 first)."
  }

  validation {
    condition     = !var.create.security_groups || var.create.networking
    error_message = "security_groups requires networking = true."
  }

  validation {
    condition     = !var.create.security_groups_dr || var.create.networking_dr
    error_message = "security_groups_dr requires networking_dr = true."
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
    condition     = !var.create.aurora || (var.create.networking && var.create.networking_dr && var.create.security_groups && var.create.security_groups_dr)
    error_message = "aurora requires networking = true, networking_dr = true, security_groups = true, and security_groups_dr = true."
  }

  validation {
    condition     = !var.create.elasticache || (var.create.networking && var.create.security_groups)
    error_message = "elasticache requires networking = true and security_groups = true."
  }

  validation {
    condition     = !var.create.amazon_mq || (var.create.networking && var.create.security_groups)
    error_message = "amazon_mq requires networking = true and security_groups = true."
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

  validation {
    condition     = !var.create.route53 || (var.create.load_balancer && var.create.cloudfront)
    error_message = "route53 requires load_balancer = true and cloudfront = true."
  }

  # ----- Tier 6 dependency validations -----

  validation {
    condition     = !var.create.backup || (var.create.iam && var.create.aurora && var.create.efs && var.create.observability)
    error_message = "backup requires iam = true, aurora = true, efs = true, and observability = true."
  }
}
