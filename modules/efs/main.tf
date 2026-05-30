terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------
# EFS File System
# -----------------------------------------------------------------------
resource "aws_efs_file_system" "main" {
  creation_token   = "${var.project}-${var.environment}-efs"
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  encrypted        = true
  kms_key_id       = var.kms_key_arn

  dynamic "lifecycle_policy" {
    for_each = var.transition_to_ia != null ? [1] : []
    content {
      transition_to_ia = var.transition_to_ia
    }
  }

  dynamic "lifecycle_policy" {
    for_each = var.transition_to_primary_storage_class != null ? [1] : []
    content {
      transition_to_primary_storage_class = var.transition_to_primary_storage_class
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-efs"
  })
}

# -----------------------------------------------------------------------
# Mount Targets — one per DB subnet (matches AZs)
# -----------------------------------------------------------------------
resource "aws_efs_mount_target" "main" {
  for_each = { for idx, subnet_id in var.db_subnet_ids : idx => subnet_id }

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = each.value
  security_groups = [var.efs_sg_id]
}

# -----------------------------------------------------------------------
# EFS Access Point — one per consuming application
# -----------------------------------------------------------------------
resource "aws_efs_access_point" "main" {
  for_each = var.access_points

  file_system_id = aws_efs_file_system.main.id

  posix_user {
    uid = each.value.uid
    gid = each.value.gid
  }

  root_directory {
    path = each.value.path
    creation_info {
      owner_uid   = each.value.uid
      owner_gid   = each.value.gid
      permissions = each.value.permissions
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-efs-ap-${each.key}"
  })
}

# -----------------------------------------------------------------------
# EFS Backup Policy
# -----------------------------------------------------------------------
resource "aws_efs_backup_policy" "main" {
  file_system_id = aws_efs_file_system.main.id

  backup_policy {
    status = "ENABLED"
  }
}
