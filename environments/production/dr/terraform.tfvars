project     = "swat"
environment = "prod-dr"
region      = "ap-south-2"

# -----------------------------------------------------------------------
# RESOURCE CREATION FLAGS
# -----------------------------------------------------------------------
# IAM roles and Aurora DR cluster are managed by the primary environment.
# Flip flags to false for cost reduction during low-traffic periods.
# -----------------------------------------------------------------------
create = {
  // Tier 1 — Foundation
  networking = true
  s3         = true

  // Tier 2 — Connectivity
  security_groups = true

  // Tier 3 — Platform
  vpc_endpoints = true
  acm           = true
  eks           = true
  elasticache   = true
  efs           = true

  // Tier 4 — Compute
  devops_ec2    = true
  load_balancer = true

  // Tier 5 — Edge
  cloudfront = true

  // Tier 6 — Operations
  observability = true
}

# -----------------------------------------------------------------------
# Networking — DR VPC
# -----------------------------------------------------------------------
vpc_cidr           = "10.1.0.0/16"
availability_zones = ["ap-south-2a", "ap-south-2b", "ap-south-2c"]

public_subnet_cidrs      = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_app_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
private_db_subnet_cidrs  = ["10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"]

# -----------------------------------------------------------------------
# DNS
# -----------------------------------------------------------------------
hosted_zone_name = "example.com"
domain_name      = "app.example.com"

# Obtain from primary environment after first apply:
#   terraform -chdir=environments/production/primary output route53_zone_id
# Set via TF_VAR_route53_zone_id
route53_zone_id = ""

# -----------------------------------------------------------------------
# IAM — obtain from primary environment after first apply:
#   terraform -chdir=environments/production/primary output
# -----------------------------------------------------------------------
eks_cluster_role_arn             = ""
eks_node_group_role_arn          = ""
devops_ec2_instance_profile_name = ""
s3_replication_role_arn          = ""

# -----------------------------------------------------------------------
# EKS — DR: reduced capacity warm standby
# -----------------------------------------------------------------------
kubernetes_version = "1.34"

eks_node_groups = {
  general = {
    instance_types = ["m5.large"]
    capacity_type  = "ON_DEMAND"
    desired_size   = 2
    min_size       = 1
    max_size       = 6
    disk_size_gb   = 50
    labels         = { "role" = "dr-standby" }
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
# Compute — DR: smaller sizes for warm standby cost reduction
# -----------------------------------------------------------------------
devops_ec2_instance_type = "t3.small"
redis_node_type          = "cache.r6g.medium"
redis_num_nodes          = 1

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
# Sensitive — set via environment variables:
#   TF_VAR_cloudfront_origin_verify_secret
# -----------------------------------------------------------------------
