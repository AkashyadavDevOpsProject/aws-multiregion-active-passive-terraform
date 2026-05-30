terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.dr]
    }
  }
}

# -----------------------------------------------------------------------
# Local: bucket definitions (primary + DR pairs)
# -----------------------------------------------------------------------
locals {
  buckets = {
    app_assets = {
      name_suffix = "app-assets"
      description = "Application static assets"
    }
    access_logs = {
      name_suffix = "access-logs"
      description = "ALB/NLB/CloudFront access logs"
    }
    terraform_artifacts = {
      name_suffix = "tf-artifacts"
      description = "Terraform plan artifacts for CI/CD"
    }
  }
}

# -----------------------------------------------------------------------
# Primary Region Buckets (ap-south-1)
# -----------------------------------------------------------------------
resource "aws_s3_bucket" "primary" {
  for_each = local.buckets

  bucket = "${var.project}-${var.environment}-${each.value.name_suffix}-${var.account_id}-${var.primary_region}"

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-${each.value.name_suffix}"
    Description = each.value.description
  })
}

resource "aws_s3_bucket_versioning" "primary" {
  for_each = local.buckets

  bucket = aws_s3_bucket.primary[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  for_each = local.buckets

  bucket = aws_s3_bucket.primary[each.key].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "primary" {
  for_each = local.buckets

  bucket                  = aws_s3_bucket.primary[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "primary" {
  for_each = { for k, v in local.buckets : k => v if k != "access_logs" }

  bucket = aws_s3_bucket.primary[each.key].id

  rule {
    id     = "transition-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Access logs bucket — short retention, no versioning lifecycle needed
resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.primary["access_logs"].id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

# -----------------------------------------------------------------------
# Cross-Region Replication (primary → DR) — app_assets only
# -----------------------------------------------------------------------
resource "aws_s3_bucket_replication_configuration" "primary_to_dr" {
  bucket = aws_s3_bucket.primary["app_assets"].id
  role   = var.s3_replication_role_arn

  rule {
    id     = "replicate-app-assets"
    status = "Enabled"

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = aws_s3_bucket.dr["app_assets"].arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = var.dr_kms_key_arn
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.dr
  ]
}

# -----------------------------------------------------------------------
# DR Region Buckets (ap-south-2)
# -----------------------------------------------------------------------
resource "aws_s3_bucket" "dr" {
  provider = aws.dr
  for_each = local.buckets

  bucket = "${var.project}-${var.environment}-${each.value.name_suffix}-${var.account_id}-${var.dr_region}"

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-${each.value.name_suffix}-dr"
    Description = "${each.value.description} (DR replica)"
  })
}

resource "aws_s3_bucket_versioning" "dr" {
  provider = aws.dr
  for_each = local.buckets

  bucket = aws_s3_bucket.dr[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dr" {
  provider = aws.dr
  for_each = local.buckets

  bucket = aws_s3_bucket.dr[each.key].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.dr_kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "dr" {
  provider = aws.dr
  for_each = local.buckets

  bucket                  = aws_s3_bucket.dr[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
