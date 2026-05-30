terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# -----------------------------------------------------------------------
# Providers
# -----------------------------------------------------------------------
provider "aws" {
  profile = "personal"
  region  = var.region

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias   = "us_east_1"
  profile = "personal"
  region  = "us-east-1"

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias   = "dr"
  profile = "personal"
  region  = var.dr_region

  default_tags {
    tags = local.common_tags
  }
}

# -----------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Akash Yadav"
  }
}

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------
# KMS Keys (one per region for data isolation)
# -----------------------------------------------------------------------
resource "aws_kms_key" "main" {
  description             = "${var.project}-${var.environment} primary region KMS key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-kms-primary"
  })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project}-${var.environment}-primary"
  target_key_id = aws_kms_key.main.key_id
}

resource "aws_kms_key" "dr" {
  provider = aws.dr

  description             = "${var.project}-${var.environment} DR region KMS key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-kms-dr"
  })
}

resource "aws_kms_alias" "dr" {
  provider = aws.dr

  name          = "alias/${var.project}-${var.environment}-dr"
  target_key_id = aws_kms_key.dr.key_id
}

# -----------------------------------------------------------------------
# Module: IAM                                              [Tier 1]
# Depends on: none
# -----------------------------------------------------------------------
module "iam" {
  count  = var.create.iam ? 1 : 0
  source = "../../../modules/iam"

  project     = var.project
  environment = var.environment
  account_id  = data.aws_caller_identity.current.account_id
  github_org  = var.github_org
  github_repo = var.github_repo

  terraform_state_bucket = var.terraform_state_bucket
  terraform_lock_table   = var.terraform_lock_table

  # S3 bucket ARNs are passed after s3 module is applied.
  # On first apply with both iam=true and s3=true, Terraform resolves s3 first
  # because iam depends on s3 outputs. Use empty lists if deploying iam alone.
  s3_source_bucket_arns       = var.create.s3 ? one(module.s3[*].source_bucket_arns) : []
  s3_destination_bucket_arns  = var.create.s3 ? one(module.s3[*].destination_bucket_arns) : []
  s3_source_kms_key_arns      = [aws_kms_key.main.arn]
  s3_destination_kms_key_arns = [aws_kms_key.dr.arn]

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: S3                                               [Tier 1]
# Depends on: iam (for replication role ARN)
# -----------------------------------------------------------------------
module "s3" {
  count  = var.create.s3 ? 1 : 0
  source = "../../../modules/s3"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  project        = var.project
  environment    = var.environment
  account_id     = data.aws_caller_identity.current.account_id
  primary_region = var.region
  dr_region      = var.dr_region
  kms_key_arn    = aws_kms_key.main.arn
  dr_kms_key_arn = aws_kms_key.dr.arn

  s3_replication_role_arn = var.create.iam ? one(module.iam[*].s3_replication_role_arn) : ""

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: Networking — Primary VPC                         [Tier 1]
# Depends on: none
# Note: TGW routes added as standalone resources below to avoid circular
#       dependency with transit_gateway module.
# -----------------------------------------------------------------------
module "networking" {
  count  = var.create.networking ? 1 : 0
  source = "../../../modules/networking"

  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr

  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: Networking — DR VPC                              [Tier 1]
# Depends on: none
# -----------------------------------------------------------------------
module "networking_dr" {
  count  = var.create.networking_dr ? 1 : 0
  source = "../../../modules/networking"

  providers = {
    aws = aws.dr
  }

  project     = var.project
  environment = "${var.environment}-dr"
  vpc_cidr    = var.dr_vpc_cidr

  availability_zones       = var.dr_availability_zones
  public_subnet_cidrs      = var.dr_public_subnet_cidrs
  private_app_subnet_cidrs = var.dr_private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.dr_private_db_subnet_cidrs

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: Transit Gateway                                  [Tier 2]
# Depends on: networking, networking_dr
# -----------------------------------------------------------------------
module "transit_gateway" {
  count  = var.create.transit_gateway ? 1 : 0
  source = "../../../modules/transit-gateway"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  project        = var.project
  environment    = var.environment
  primary_region = var.region
  dr_region      = var.dr_region

  primary_vpc_id                 = var.create.networking ? one(module.networking[*].vpc_id) : ""
  primary_vpc_cidr               = var.vpc_cidr
  primary_private_app_subnet_ids = var.create.networking ? one(module.networking[*].private_app_subnet_ids_list) : []

  dr_vpc_id                 = var.create.networking_dr ? one(module.networking_dr[*].vpc_id) : ""
  dr_vpc_cidr               = var.dr_vpc_cidr
  dr_private_app_subnet_ids = var.create.networking_dr ? one(module.networking_dr[*].private_app_subnet_ids_list) : []

  tags = local.common_tags
}

# TGW routes — managed here instead of inside networking module to break circular dependency.
# primary private-app route tables → DR CIDR via primary TGW
resource "aws_route" "primary_app_to_dr" {
  for_each = var.create.transit_gateway ? coalesce(one(module.networking[*].private_app_route_table_ids), {}) : {}

  route_table_id         = each.value
  destination_cidr_block = var.dr_vpc_cidr
  transit_gateway_id     = one(module.transit_gateway[*].primary_tgw_id)

  depends_on = [module.transit_gateway, module.networking]
}

resource "aws_route" "primary_db_to_dr" {
  count = var.create.transit_gateway ? 1 : 0

  route_table_id         = one(module.networking[*].private_db_route_table_id)
  destination_cidr_block = var.dr_vpc_cidr
  transit_gateway_id     = one(module.transit_gateway[*].primary_tgw_id)

  depends_on = [module.transit_gateway, module.networking]
}

# DR private-app route tables → primary CIDR via DR TGW
resource "aws_route" "dr_app_to_primary" {
  for_each = var.create.transit_gateway ? coalesce(one(module.networking_dr[*].private_app_route_table_ids), {}) : {}
  provider = aws.dr

  route_table_id         = each.value
  destination_cidr_block = var.vpc_cidr
  transit_gateway_id     = one(module.transit_gateway[*].dr_tgw_id)

  depends_on = [module.transit_gateway, module.networking_dr]
}

resource "aws_route" "dr_db_to_primary" {
  count    = var.create.transit_gateway ? 1 : 0
  provider = aws.dr

  route_table_id         = one(module.networking_dr[*].private_db_route_table_id)
  destination_cidr_block = var.vpc_cidr
  transit_gateway_id     = one(module.transit_gateway[*].dr_tgw_id)

  depends_on = [module.transit_gateway, module.networking_dr]
}

# -----------------------------------------------------------------------
# Module: Security Groups — Primary                        [Tier 2]
# Depends on: networking
# -----------------------------------------------------------------------
module "security_groups" {
  count  = var.create.security_groups ? 1 : 0
  source = "../../../modules/security-groups"

  project     = var.project
  environment = var.environment
  vpc_id      = var.create.networking ? one(module.networking[*].vpc_id) : ""
  vpc_cidr    = var.vpc_cidr

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: Security Groups — DR                             [Tier 2]
# Depends on: networking_dr
# -----------------------------------------------------------------------
module "security_groups_dr" {
  count  = var.create.security_groups_dr ? 1 : 0
  source = "../../../modules/security-groups"

  providers = {
    aws = aws.dr
  }

  project     = var.project
  environment = "${var.environment}-dr"
  vpc_id      = var.create.networking_dr ? one(module.networking_dr[*].vpc_id) : ""
  vpc_cidr    = var.dr_vpc_cidr

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: VPC Endpoints — Primary                          [Tier 3]
# Depends on: networking, security_groups
# -----------------------------------------------------------------------
module "vpc_endpoints" {
  count  = var.create.vpc_endpoints ? 1 : 0
  source = "../../../modules/vpc-endpoints"

  project     = var.project
  environment = var.environment
  region      = var.region
  vpc_id      = var.create.networking ? one(module.networking[*].vpc_id) : ""

  private_app_subnet_ids      = var.create.networking ? one(module.networking[*].private_app_subnet_ids_list) : []
  private_app_route_table_ids = var.create.networking ? one(module.networking[*].private_app_route_table_ids) : {}
  private_db_route_table_id   = var.create.networking ? one(module.networking[*].private_db_route_table_id) : ""
  vpc_endpoints_sg_id         = var.create.security_groups ? one(module.security_groups[*].vpc_endpoints_sg_id) : ""

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: ACM (primary + CloudFront cert)                  [Tier 3]
# Depends on: var.route53_zone_id (variable — avoids circular dep with route53 module)
# -----------------------------------------------------------------------
module "acm" {
  count  = var.create.acm ? 1 : 0
  source = "../../../modules/acm"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project                   = var.project
  environment               = var.environment
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  route53_zone_id           = var.route53_zone_id

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: EKS — Primary                                   [Tier 3]
# Depends on: iam, networking, security_groups
# -----------------------------------------------------------------------
module "eks" {
  count  = var.create.eks ? 1 : 0
  source = "../../../modules/eks"

  project     = var.project
  environment = var.environment

  cluster_role_arn    = var.create.iam ? one(module.iam[*].eks_cluster_role_arn) : ""
  node_group_role_arn = var.create.iam ? one(module.iam[*].eks_node_group_role_arn) : ""

  private_app_subnet_ids = var.create.networking ? one(module.networking[*].private_app_subnet_ids_list) : []
  cluster_sg_id          = var.create.security_groups ? one(module.security_groups[*].eks_cluster_sg_id) : ""
  kms_key_arn            = aws_kms_key.main.arn

  kubernetes_version     = var.kubernetes_version
  endpoint_public_access = false

  node_groups    = var.eks_node_groups
  addon_versions = var.eks_addon_versions

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: DevOps EC2                                       [Tier 4]
# Depends on: iam, networking, security_groups, eks
# -----------------------------------------------------------------------
module "devops_ec2" {
  count  = var.create.devops_ec2 ? 1 : 0
  source = "../../../modules/devops-ec2"

  project               = var.project
  environment           = var.environment
  region                = var.region
  instance_type         = var.devops_ec2_instance_type
  subnet_id             = var.create.networking ? one(module.networking[*].private_app_subnet_ids_list)[0] : ""
  security_group_id     = var.create.security_groups ? one(module.security_groups[*].devops_ec2_sg_id) : ""
  instance_profile_name = var.create.iam ? one(module.iam[*].devops_ec2_instance_profile_name) : ""
  kms_key_arn           = aws_kms_key.main.arn
  eks_cluster_name      = var.create.eks ? one(module.eks[*].cluster_name) : ""

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: Aurora Global DB                                 [Tier 3]
# Depends on: networking, networking_dr, security_groups, security_groups_dr
# -----------------------------------------------------------------------
module "aurora" {
  count  = var.create.aurora ? 1 : 0
  source = "../../../modules/aurora"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  project        = var.project
  environment    = var.environment
  primary_region = var.region
  dr_region      = var.dr_region

  database_name  = var.aurora_database_name
  engine_version = var.aurora_engine_version

  primary_db_subnet_ids = var.create.networking ? one(module.networking[*].private_db_subnet_ids_list) : []
  dr_db_subnet_ids      = var.create.networking_dr ? one(module.networking_dr[*].private_db_subnet_ids_list) : []
  aurora_sg_id          = var.create.security_groups ? one(module.security_groups[*].aurora_sg_id) : ""
  dr_aurora_sg_id       = var.create.security_groups_dr ? one(module.security_groups_dr[*].aurora_sg_id) : ""

  kms_key_arn    = aws_kms_key.main.arn
  dr_kms_key_arn = aws_kms_key.dr.arn

  primary_instance_count = var.aurora_primary_instance_count
  primary_instance_class = var.aurora_primary_instance_class
  dr_instance_count      = var.aurora_dr_instance_count
  dr_instance_class      = var.aurora_dr_instance_class

  deletion_protection   = true
  backup_retention_days = var.aurora_backup_retention_days

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: ElastiCache Redis                                [Tier 3]
# Depends on: networking, security_groups
# -----------------------------------------------------------------------
module "elasticache" {
  count  = var.create.elasticache ? 1 : 0
  source = "../../../modules/elasticache"

  project     = var.project
  environment = var.environment

  node_type         = var.redis_node_type
  num_cache_nodes   = var.redis_num_nodes
  db_subnet_ids     = var.create.networking ? one(module.networking[*].private_db_subnet_ids_list) : []
  elasticache_sg_id = var.create.security_groups ? one(module.security_groups[*].elasticache_sg_id) : ""
  kms_key_arn       = aws_kms_key.main.arn

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: Amazon MQ                                        [Tier 3]
# Depends on: networking, security_groups
# -----------------------------------------------------------------------
module "amazon_mq" {
  count  = var.create.amazon_mq ? 1 : 0
  source = "../../../modules/amazon-mq"

  project     = var.project
  environment = var.environment

  db_subnet_ids      = var.create.networking ? one(module.networking[*].private_db_subnet_ids_list) : []
  amazon_mq_sg_id    = var.create.security_groups ? one(module.security_groups[*].amazon_mq_sg_id) : ""
  kms_key_arn        = aws_kms_key.main.arn
  mq_admin_secret_id = var.mq_admin_secret_id

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: EFS                                              [Tier 3]
# Depends on: networking, security_groups
# -----------------------------------------------------------------------
module "efs" {
  count  = var.create.efs ? 1 : 0
  source = "../../../modules/efs"

  project     = var.project
  environment = var.environment

  db_subnet_ids = var.create.networking ? one(module.networking[*].private_db_subnet_ids_list) : []
  efs_sg_id     = var.create.security_groups ? one(module.security_groups[*].efs_sg_id) : ""
  kms_key_arn   = aws_kms_key.main.arn
  access_points = var.efs_access_points

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: Load Balancer                                    [Tier 4]
# Depends on: networking, security_groups, acm, s3
# -----------------------------------------------------------------------
module "load_balancer" {
  count  = var.create.load_balancer ? 1 : 0
  source = "../../../modules/load-balancer"

  project     = var.project
  environment = var.environment

  vpc_id                 = var.create.networking ? one(module.networking[*].vpc_id) : ""
  public_subnet_ids      = var.create.networking ? one(module.networking[*].public_subnet_ids_list) : []
  private_app_subnet_ids = var.create.networking ? one(module.networking[*].private_app_subnet_ids_list) : []
  nlb_sg_id              = var.create.security_groups ? one(module.security_groups[*].nlb_public_sg_id) : ""
  alb_sg_id              = var.create.security_groups ? one(module.security_groups[*].alb_private_sg_id) : ""
  certificate_arn        = var.create.acm ? one(module.acm[*].primary_certificate_arn) : ""

  access_logs_bucket         = var.create.s3 ? one(module.s3[*].access_logs_bucket_name) : ""
  enable_deletion_protection = true

  target_groups  = var.alb_target_groups
  listener_rules = var.alb_listener_rules

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: CloudFront + WAF                                 [Tier 5]
# Depends on: load_balancer, acm, s3
# -----------------------------------------------------------------------
module "cloudfront" {
  count  = var.create.cloudfront ? 1 : 0
  source = "../../../modules/cloudfront"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project     = var.project
  environment = var.environment

  nlb_dns_name               = var.create.load_balancer ? one(module.load_balancer[*].nlb_dns_name) : ""
  domain_aliases             = [var.domain_name]
  cloudfront_certificate_arn = var.create.acm ? one(module.acm[*].cloudfront_certificate_arn) : ""
  origin_verify_secret       = var.cloudfront_origin_verify_secret
  access_logs_bucket         = var.create.s3 ? one(module.s3[*].access_logs_bucket_name) : ""

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: Route 53                                         [Tier 5]
# Depends on: load_balancer, cloudfront
# -----------------------------------------------------------------------
module "route53" {
  count  = var.create.route53 ? 1 : 0
  source = "../../../modules/route53"

  project     = var.project
  environment = var.environment

  hosted_zone_name = var.hosted_zone_name
  domain_name      = var.domain_name

  primary_nlb_dns_name      = var.create.load_balancer ? one(module.load_balancer[*].nlb_dns_name) : ""
  dr_nlb_dns_name           = var.dr_nlb_dns_name
  cloudfront_domain_name    = var.create.cloudfront ? one(module.cloudfront[*].domain_name) : ""
  dr_cloudfront_domain_name = var.dr_cloudfront_domain_name

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: Observability                                    [Tier 6]
# Depends on: none (standalone — uses KMS key only)
# -----------------------------------------------------------------------
module "observability" {
  count  = var.create.observability ? 1 : 0
  source = "../../../modules/observability"

  project     = var.project
  environment = var.environment
  region      = var.region

  kms_key_arn           = aws_kms_key.main.arn
  alarm_email_endpoints = var.alarm_email_endpoints

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: AWS Backup                                       [Tier 6]
# Depends on: iam, aurora, efs, observability
# -----------------------------------------------------------------------
module "backup" {
  count  = var.create.backup ? 1 : 0
  source = "../../../modules/backup"

  project     = var.project
  environment = var.environment

  kms_key_arn          = aws_kms_key.main.arn
  backup_role_arn      = var.create.iam ? one(module.iam[*].backup_role_arn) : ""
  aurora_cluster_arns  = var.create.aurora ? [one(module.aurora[*].primary_cluster_id)] : []
  efs_file_system_arns = var.create.efs ? [one(module.efs[*].file_system_arn)] : []
  alarm_sns_topic_arns = var.create.observability ? [one(module.observability[*].alarms_sns_topic_arn)] : []

  tags = local.common_tags
}
