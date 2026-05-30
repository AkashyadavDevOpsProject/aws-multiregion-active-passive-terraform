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
# Amazon MQ Broker (ActiveMQ, ACTIVE_STANDBY_MULTI_AZ)
# Master credentials sourced from Secrets Manager — never hardcoded
# -----------------------------------------------------------------------
data "aws_secretsmanager_secret_version" "mq_admin" {
  secret_id = var.mq_admin_secret_id
}

locals {
  mq_credentials = jsondecode(data.aws_secretsmanager_secret_version.mq_admin.secret_string)
}

resource "aws_mq_broker" "main" {
  broker_name        = "${var.project}-${var.environment}-mq"
  engine_type        = var.engine_type
  engine_version     = var.engine_version
  deployment_mode    = var.deployment_mode
  host_instance_type = var.host_instance_type
  storage_type       = "efs"

  subnet_ids         = var.deployment_mode == "ACTIVE_STANDBY_MULTI_AZ" ? var.db_subnet_ids : [var.db_subnet_ids[0]]
  security_groups    = [var.amazon_mq_sg_id]

  publicly_accessible     = false
  auto_minor_version_upgrade = false

  encryption_options {
    kms_key_id        = var.kms_key_arn
    use_aws_owned_key = false
  }

  logs {
    general = true
    audit   = var.engine_type == "ActiveMQ" ? true : null
  }

  maintenance_window_start_time {
    day_of_week = "SUNDAY"
    time_of_day = "04:00"
    time_zone   = "UTC"
  }

  user {
    username       = local.mq_credentials["username"]
    password       = local.mq_credentials["password"]
    console_access = false
    groups         = []
  }

  user {
    username       = local.mq_credentials["admin_username"]
    password       = local.mq_credentials["admin_password"]
    console_access = true
    groups         = []
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-mq"
  })
}
