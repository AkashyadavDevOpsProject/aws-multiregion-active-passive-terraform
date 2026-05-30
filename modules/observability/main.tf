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
# CloudWatch Log Groups
# -----------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/${var.project}/${var.environment}/application"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-log-group-application"
  })
}

resource "aws_cloudwatch_log_group" "eks_control_plane" {
  name              = "/aws/eks/${var.project}-${var.environment}-eks-cluster/cluster"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# -----------------------------------------------------------------------
# X-Ray Group
# -----------------------------------------------------------------------
resource "aws_xray_group" "main" {
  group_name        = "${var.project}-${var.environment}"
  filter_expression = "service(\"${var.project}-${var.environment}\")"

  insights_configuration {
    insights_enabled      = true
    notifications_enabled = true
  }

  tags = var.tags
}

# -----------------------------------------------------------------------
# CloudWatch Dashboard
# -----------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-${var.environment}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "EKS Node CPU Utilization"
          region = var.region
          metrics = [
            ["ContainerInsights", "node_cpu_utilization", "ClusterName", "${var.project}-${var.environment}-eks-cluster"]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Aurora DB Connections"
          region = var.region
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", "${var.project}-${var.environment}-aurora-primary"]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ElastiCache Redis CPU"
          region = var.region
          metrics = [
            ["AWS/ElastiCache", "EngineCPUUtilization", "ReplicationGroupId", "${var.project}-${var.environment}-redis"]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ALB Request Count"
          region = var.region
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${var.project}-${var.environment}-alb-private"]
          ]
          period = 60
          stat   = "Sum"
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------
# CloudWatch Alarms — EKS
# -----------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "eks_node_cpu" {
  alarm_name          = "${var.project}-${var.environment}-eks-node-cpu-high"
  alarm_description   = "EKS node CPU utilization above 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    ClusterName = "${var.project}-${var.environment}-eks-cluster"
  }

  tags = var.tags
}

# -----------------------------------------------------------------------
# CloudWatch Alarms — Aurora
# -----------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "aurora_cpu" {
  alarm_name          = "${var.project}-${var.environment}-aurora-cpu-high"
  alarm_description   = "Aurora CPU utilization above 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    DBClusterIdentifier = "${var.project}-${var.environment}-aurora-primary"
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "aurora_replica_lag" {
  alarm_name          = "${var.project}-${var.environment}-aurora-replica-lag"
  alarm_description   = "Aurora global replication lag above 30s — DR RPO at risk"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "AuroraGlobalDBReplicationLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 30000
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    DBClusterIdentifier = "${var.project}-${var.environment}-aurora-primary"
  }

  tags = var.tags
}

# -----------------------------------------------------------------------
# CloudWatch Alarms — ElastiCache
# -----------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "${var.project}-${var.environment}-redis-cpu-high"
  alarm_description   = "Redis engine CPU above 70%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    ReplicationGroupId = "${var.project}-${var.environment}-redis"
  }

  tags = var.tags
}

# -----------------------------------------------------------------------
# SNS Topic for Alarms
# -----------------------------------------------------------------------
resource "aws_sns_topic" "alarms" {
  name              = "${var.project}-${var.environment}-alarms"
  kms_master_key_id = var.kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-alarms"
  })
}

resource "aws_sns_topic_subscription" "alarms_email" {
  count = length(var.alarm_email_endpoints)

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email_endpoints[count.index]
}
