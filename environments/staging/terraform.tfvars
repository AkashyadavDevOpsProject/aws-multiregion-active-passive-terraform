project     = "swat"
environment = "staging"
region      = "ap-south-1"

# -----------------------------------------------------------------------
# RESOURCE CREATION FLAGS
# -----------------------------------------------------------------------
# Staging: all modules enabled by default. Set flags to false to save costs
# during off-hours or when testing a specific tier in isolation.
# -----------------------------------------------------------------------
create = {
  // Tier 1 — Foundation
  iam        = true
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

vpc_cidr           = "10.2.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b"]

public_subnet_cidrs      = ["10.2.1.0/24", "10.2.2.0/24"]
private_app_subnet_cidrs = ["10.2.11.0/24", "10.2.12.0/24"]
private_db_subnet_cidrs  = ["10.2.21.0/24", "10.2.22.0/24"]

hosted_zone_name          = "example.com"
domain_name               = "staging.example.com"
subject_alternative_names = []

# Set via TF_VAR_route53_zone_id
route53_zone_id = ""

github_org  = "akashyadavdevops"
github_repo = "terraform-swat-aws-dr"

terraform_state_bucket = "terformstatefile2026-077154311968-ap-south-1-an"
terraform_lock_table   = "terraform-state-lock"

kubernetes_version = "1.34"

eks_node_groups = {
  general = {
    instance_types = ["t3.large"]
    capacity_type  = "SPOT"
    desired_size   = 2
    min_size       = 1
    max_size       = 5
    disk_size_gb   = 30
    labels         = {}
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

alarm_email_endpoints = []
