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
# Backup Vault
# -----------------------------------------------------------------------
resource "aws_backup_vault" "main" {
  name        = "${var.project}-${var.environment}-backup-vault"
  kms_key_arn = var.kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-backup-vault"
  })
}

resource "aws_backup_vault_lock_configuration" "main" {
  count = var.enable_vault_lock ? 1 : 0

  backup_vault_name   = aws_backup_vault.main.name
  min_retention_days  = var.vault_lock_min_retention_days
  max_retention_days  = var.vault_lock_max_retention_days
  changeable_for_days = var.vault_lock_changeable_days
}

# -----------------------------------------------------------------------
# Backup Plan
# -----------------------------------------------------------------------
resource "aws_backup_plan" "main" {
  name = "${var.project}-${var.environment}-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 1 * * ? *)"

    start_window      = 60
    completion_window = 180

    lifecycle {
      delete_after = var.daily_retention_days
    }

    recovery_point_tags = var.tags
  }

  rule {
    rule_name         = "weekly-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 ? * SUN *)"

    start_window      = 60
    completion_window = 360

    lifecycle {
      delete_after = var.weekly_retention_days
    }

    recovery_point_tags = var.tags
  }

  rule {
    rule_name         = "monthly-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 3 1 * ? *)"

    start_window      = 60
    completion_window = 720

    lifecycle {
      cold_storage_after = 30
      delete_after       = var.monthly_retention_days
    }

    recovery_point_tags = var.tags
  }

  tags = var.tags
}

# -----------------------------------------------------------------------
# Backup Selection — Aurora Clusters
# -----------------------------------------------------------------------
resource "aws_backup_selection" "aurora" {
  name          = "${var.project}-${var.environment}-backup-aurora"
  plan_id       = aws_backup_plan.main.id
  iam_role_arn  = var.backup_role_arn

  resources = var.aurora_cluster_arns
}

# -----------------------------------------------------------------------
# Backup Selection — EFS File Systems
# -----------------------------------------------------------------------
resource "aws_backup_selection" "efs" {
  name         = "${var.project}-${var.environment}-backup-efs"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = var.backup_role_arn

  resources = var.efs_file_system_arns
}

# -----------------------------------------------------------------------
# CloudWatch Alarm — Failed Backup Jobs
# -----------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "backup_failures" {
  alarm_name          = "${var.project}-${var.environment}-backup-job-failures"
  alarm_description   = "Alert when AWS Backup jobs fail"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfBackupJobsFailed"
  namespace           = "AWS/Backup"
  period              = 86400
  statistic           = "Sum"
  threshold           = 1
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    BackupVaultName = aws_backup_vault.main.name
  }

  tags = var.tags
}
