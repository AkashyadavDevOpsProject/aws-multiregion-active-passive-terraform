project     = "swat"
environment = "prod"
region      = "ap-south-1"
dr_region   = "ap-south-2"

# -----------------------------------------------------------------------
# RESOURCE CREATION FLAGS
# -----------------------------------------------------------------------
# Set any flag to false to skip that module on the next apply.
# Dependency tiers must be respected — validation blocks enforce this at plan time.
# See flags.tf for full tier documentation and dependency rules.
# -----------------------------------------------------------------------
create = {
  // Tier 1 — Foundation (no dependencies)
  iam           = true
  networking    = true
  networking_dr = true
  s3            = true

  // Tier 2 — Connectivity (requires Tier 1)
  transit_gateway    = true
  security_groups    = true
  security_groups_dr = true

  // Tier 3 — Platform (requires Tier 2)
  vpc_endpoints = true
  acm           = true
  eks           = true
  aurora        = true
  elasticache   = true
  amazon_mq     = true
  efs           = true

  // Tier 4 — Compute (requires Tier 3)
  devops_ec2    = true
  load_balancer = true

  // Tier 5 — Edge (requires Tier 4)
  cloudfront = true
  route53    = true

  // Tier 6 — Operations (requires Tier 3-5)
  observability = true
  backup        = true
}

# -----------------------------------------------------------------------
# Networking — Primary (ap-south-1)
# -----------------------------------------------------------------------
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]

public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_app_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
private_db_subnet_cidrs  = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

# -----------------------------------------------------------------------
# Networking — DR (ap-south-2)
# -----------------------------------------------------------------------
dr_vpc_cidr           = "10.1.0.0/16"
dr_availability_zones = ["ap-south-2a", "ap-south-2b", "ap-south-2c"]

dr_public_subnet_cidrs      = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
dr_private_app_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
dr_private_db_subnet_cidrs  = ["10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"]

# -----------------------------------------------------------------------
# DNS / ACM
# -----------------------------------------------------------------------
hosted_zone_name          = "example.com"
domain_name               = "app.example.com"
subject_alternative_names = ["*.example.com"]

# Obtain via: aws route53 list-hosted-zones-by-name --dns-name example.com --query 'HostedZones[0].Id'
# Format: Z1234567890ABC (strip the /hostedzone/ prefix)
route53_zone_id = ""

# -----------------------------------------------------------------------
# IAM / GitHub
# -----------------------------------------------------------------------
github_org  = "akashyadavdevops"
github_repo = "terraform-swat-aws-dr"

# -----------------------------------------------------------------------
# EKS
# -----------------------------------------------------------------------
kubernetes_version = "1.34"

eks_node_groups = {
  general = {
    instance_types = ["m5.xlarge"]
    capacity_type  = "ON_DEMAND"
    desired_size   = 3
    min_size       = 2
    max_size       = 10
    disk_size_gb   = 50
    labels         = {}
    taints         = []
  }
  spot = {
    instance_types = ["m5.xlarge", "m5.2xlarge", "m4.xlarge"]
    capacity_type  = "SPOT"
    desired_size   = 2
    min_size       = 0
    max_size       = 20
    disk_size_gb   = 50
    labels         = { "node-type" = "spot" }
    taints         = []
  }
}

eks_addon_versions = {
  coredns    = "v1.11.4-eksbuild.2"
  kube_proxy = "v1.34.0-eksbuild.2"
  vpc_cni    = "v1.19.3-eksbuild.1"
  ebs_csi    = "v1.40.0-eksbuild.1"
  efs_csi    = "v2.1.6-eksbuild.1"
}

# -----------------------------------------------------------------------
# DevOps EC2
# -----------------------------------------------------------------------
devops_ec2_instance_type = "t3.medium"

# -----------------------------------------------------------------------
# Aurora
# -----------------------------------------------------------------------
aurora_database_name          = "swatdb"
aurora_engine_version         = "16.2"
aurora_primary_instance_count = 2
aurora_primary_instance_class = "db.r6g.large"
aurora_dr_instance_count      = 1
aurora_dr_instance_class      = "db.r6g.medium"
aurora_backup_retention_days  = 7

# -----------------------------------------------------------------------
# ElastiCache Redis
# -----------------------------------------------------------------------
redis_node_type = "cache.r6g.large"
redis_num_nodes = 2

# -----------------------------------------------------------------------
# Amazon MQ
# -----------------------------------------------------------------------
mq_admin_secret_id = "swat/prod/amazon-mq/admin"

# -----------------------------------------------------------------------
# EFS Access Points
# -----------------------------------------------------------------------
efs_access_points = {
  shared = {
    path        = "/shared"
    uid         = 1000
    gid         = 1000
    permissions = "755"
  }
}

# -----------------------------------------------------------------------
# Load Balancer
# -----------------------------------------------------------------------
alb_target_groups = {
  api = {
    port              = 8080
    health_check_path = "/health"
  }
}

alb_listener_rules = {
  api = {
    priority         = 100
    target_group_key = "api"
    path_patterns    = ["/api/*"]
  }
}

# -----------------------------------------------------------------------
# Observability
# -----------------------------------------------------------------------
alarm_email_endpoints = ["devops@example.com"]

# -----------------------------------------------------------------------
# Sensitive variables — set via TF_VAR_* environment variables, NOT here
# cloudfront_origin_verify_secret = set via TF_VAR_cloudfront_origin_verify_secret
# dr_nlb_dns_name                 = set after DR environment is applied
# dr_cloudfront_domain_name       = set after DR environment is applied
# -----------------------------------------------------------------------
