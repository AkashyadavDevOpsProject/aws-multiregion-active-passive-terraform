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

provider "aws" {
  profile = "devops-admin"
  region  = var.region

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias   = "us_east_1"
  profile = "devops-admin"
  region  = "us-east-1"

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Akash Yadav"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "main" {
  description             = "${var.project}-${var.environment} KMS key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-kms" })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project}-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

# -----------------------------------------------------------------------
# Module: IAM                                              [Tier 1]
# Depends on: none
# -----------------------------------------------------------------------
module "iam" {
  count  = var.create.iam ? 1 : 0
  source = "../../modules/iam"

  project     = var.project
  environment = var.environment
  account_id  = data.aws_caller_identity.current.account_id
  github_org  = var.github_org
  github_repo = var.github_repo

  terraform_state_bucket = var.terraform_state_bucket
  terraform_lock_table   = var.terraform_lock_table

  s3_source_bucket_arns       = var.create.s3 ? one(module.s3[*].source_bucket_arns) : []
  s3_destination_bucket_arns  = var.create.s3 ? one(module.s3[*].destination_bucket_arns) : []
  s3_source_kms_key_arns      = [aws_kms_key.main.arn]
  s3_destination_kms_key_arns = [aws_kms_key.main.arn]

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: Networking                                       [Tier 1]
# Depends on: none
# -----------------------------------------------------------------------
module "networking" {
  count  = var.create.networking ? 1 : 0
  source = "../../modules/networking"

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
# Module: S3                                               [Tier 1]
# Depends on: iam (for replication role ARN)
# -----------------------------------------------------------------------
module "s3" {
  count  = var.create.s3 ? 1 : 0
  source = "../../modules/s3"

  providers = {
    aws    = aws
    aws.dr = aws
  }

  project        = var.project
  environment    = var.environment
  account_id     = data.aws_caller_identity.current.account_id
  primary_region = var.region
  dr_region      = var.region

  kms_key_arn             = aws_kms_key.main.arn
  dr_kms_key_arn          = aws_kms_key.main.arn
  s3_replication_role_arn = var.create.iam ? one(module.iam[*].s3_replication_role_arn) : ""

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: Security Groups                                  [Tier 2]
# Depends on: networking
# -----------------------------------------------------------------------
module "security_groups" {
  count  = var.create.security_groups ? 1 : 0
  source = "../../modules/security-groups"

  project     = var.project
  environment = var.environment
  vpc_id      = var.create.networking ? one(module.networking[*].vpc_id) : ""
  vpc_cidr    = var.vpc_cidr

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: VPC Endpoints                                    [Tier 3]
# Depends on: networking, security_groups
# -----------------------------------------------------------------------
module "vpc_endpoints" {
  count  = var.create.vpc_endpoints ? 1 : 0
  source = "../../modules/vpc-endpoints"

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
# Module: ACM                                              [Tier 3]
# Depends on: var.route53_zone_id (set in tfvars)
# -----------------------------------------------------------------------
module "acm" {
  count  = var.create.acm ? 1 : 0
  source = "../../modules/acm"

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
# Module: EKS                                              [Tier 3]
# Depends on: iam, networking, security_groups
# -----------------------------------------------------------------------
module "eks" {
  count  = var.create.eks ? 1 : 0
  source = "../../modules/eks"

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
  source = "../../modules/devops-ec2"

  project               = var.project
  environment           = var.environment
  region                = var.region
  instance_type         = "t3.small"
  subnet_id             = var.create.networking ? one(module.networking[*].private_app_subnet_ids_list)[0] : ""
  security_group_id     = var.create.security_groups ? one(module.security_groups[*].devops_ec2_sg_id) : ""
  instance_profile_name = var.create.iam ? one(module.iam[*].devops_ec2_instance_profile_name) : ""
  kms_key_arn           = aws_kms_key.main.arn
  eks_cluster_name      = var.create.eks ? one(module.eks[*].cluster_name) : ""

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: ElastiCache Redis                                [Tier 3]
# Depends on: networking, security_groups
# -----------------------------------------------------------------------
module "elasticache" {
  count  = var.create.elasticache ? 1 : 0
  source = "../../modules/elasticache"

  project     = var.project
  environment = var.environment

  node_type         = "cache.t4g.medium"
  num_cache_nodes   = 1
  db_subnet_ids     = var.create.networking ? one(module.networking[*].private_db_subnet_ids_list) : []
  elasticache_sg_id = var.create.security_groups ? one(module.security_groups[*].elasticache_sg_id) : ""
  kms_key_arn       = aws_kms_key.main.arn

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: EFS                                              [Tier 3]
# Depends on: networking, security_groups
# -----------------------------------------------------------------------
module "efs" {
  count  = var.create.efs ? 1 : 0
  source = "../../modules/efs"

  project       = var.project
  environment   = var.environment
  db_subnet_ids = var.create.networking ? one(module.networking[*].private_db_subnet_ids_list) : []
  efs_sg_id     = var.create.security_groups ? one(module.security_groups[*].efs_sg_id) : ""
  kms_key_arn   = aws_kms_key.main.arn

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: Load Balancer                                    [Tier 4]
# Depends on: networking, security_groups, acm, s3
# -----------------------------------------------------------------------
module "load_balancer" {
  count  = var.create.load_balancer ? 1 : 0
  source = "../../modules/load-balancer"

  project     = var.project
  environment = var.environment

  vpc_id                 = var.create.networking ? one(module.networking[*].vpc_id) : ""
  public_subnet_ids      = var.create.networking ? one(module.networking[*].public_subnet_ids_list) : []
  private_app_subnet_ids = var.create.networking ? one(module.networking[*].private_app_subnet_ids_list) : []
  nlb_sg_id              = var.create.security_groups ? one(module.security_groups[*].nlb_public_sg_id) : ""
  alb_sg_id              = var.create.security_groups ? one(module.security_groups[*].alb_private_sg_id) : ""
  certificate_arn        = var.create.acm ? one(module.acm[*].primary_certificate_arn) : ""

  access_logs_bucket         = var.create.s3 ? one(module.s3[*].access_logs_bucket_name) : ""
  enable_deletion_protection = false

  target_groups  = var.alb_target_groups
  listener_rules = var.alb_listener_rules

  tags = local.common_tags
}

# -----------------------------------------------------------------------
# Module: CloudFront                                       [Tier 5]
# Depends on: load_balancer, acm, s3
# -----------------------------------------------------------------------
module "cloudfront" {
  count  = var.create.cloudfront ? 1 : 0
  source = "../../modules/cloudfront"

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
# Module: Observability                                    [Tier 6]
# Depends on: none (standalone)
# -----------------------------------------------------------------------
module "observability" {
  count  = var.create.observability ? 1 : 0
  source = "../../modules/observability"

  project     = var.project
  environment = var.environment
  region      = var.region

  kms_key_arn           = aws_kms_key.main.arn
  alarm_email_endpoints = var.alarm_email_endpoints

  tags = local.common_tags
}
