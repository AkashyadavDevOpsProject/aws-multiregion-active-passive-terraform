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
# Aurora Global Cluster
# -----------------------------------------------------------------------
resource "aws_rds_global_cluster" "main" {
  global_cluster_identifier = "${var.project}-${var.environment}-aurora-global"
  engine                    = "aurora-postgresql"
  engine_version            = var.engine_version
  database_name             = var.database_name
  deletion_protection       = var.deletion_protection
  storage_encrypted         = true

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------
# Primary Cluster Subnet Group (ap-south-1)
# -----------------------------------------------------------------------
resource "aws_db_subnet_group" "primary" {
  name        = "${var.project}-${var.environment}-aurora-subnet-group"
  description = "Aurora subnet group — private DB subnets in ${var.primary_region}"
  subnet_ids  = var.primary_db_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-aurora-subnet-group"
  })
}

# -----------------------------------------------------------------------
# Aurora Cluster Parameter Group
# -----------------------------------------------------------------------
resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${var.project}-${var.environment}-aurora-pg-cluster-params"
  family      = var.parameter_group_family
  description = "Aurora PostgreSQL cluster parameters"

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = var.tags
}

resource "aws_db_parameter_group" "main" {
  name        = "${var.project}-${var.environment}-aurora-pg-instance-params"
  family      = var.parameter_group_family
  description = "Aurora PostgreSQL instance parameters"

  tags = var.tags
}

# -----------------------------------------------------------------------
# Primary Aurora Cluster (ap-south-1)
# -----------------------------------------------------------------------
resource "aws_rds_cluster" "primary" {
  cluster_identifier        = "${var.project}-${var.environment}-aurora-primary"
  global_cluster_identifier = aws_rds_global_cluster.main.id
  engine                    = "aurora-postgresql"
  engine_version            = var.engine_version
  database_name             = var.database_name
  master_username           = var.master_username
  manage_master_user_password = true

  db_subnet_group_name            = aws_db_subnet_group.primary.name
  vpc_security_group_ids          = [var.aurora_sg_id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  backup_retention_period   = var.backup_retention_days
  preferred_backup_window   = "02:00-03:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  deletion_protection = var.deletion_protection
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.project}-${var.environment}-aurora-final-snapshot"

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-aurora-primary"
  })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [global_cluster_identifier]
  }

  depends_on = [aws_rds_global_cluster.main]
}

# -----------------------------------------------------------------------
# Primary Cluster Instances
# -----------------------------------------------------------------------
resource "aws_rds_cluster_instance" "primary" {
  count = var.primary_instance_count

  identifier         = "${var.project}-${var.environment}-aurora-primary-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.primary.id
  instance_class     = var.primary_instance_class
  engine             = "aurora-postgresql"
  engine_version     = var.engine_version

  db_parameter_group_name = aws_db_parameter_group.main.name

  auto_minor_version_upgrade = false
  publicly_accessible        = false

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = var.kms_key_arn
  performance_insights_retention_period = 7

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-aurora-primary-${count.index + 1}"
  })
}

# -----------------------------------------------------------------------
# DR Cluster Subnet Group (ap-south-2)
# -----------------------------------------------------------------------
resource "aws_db_subnet_group" "dr" {
  provider = aws.dr

  name        = "${var.project}-${var.environment}-aurora-subnet-group-dr"
  description = "Aurora subnet group — private DB subnets in ${var.dr_region}"
  subnet_ids  = var.dr_db_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-aurora-subnet-group-dr"
  })
}

# -----------------------------------------------------------------------
# DR Aurora Cluster (ap-south-2) — secondary/read-only member of global cluster
# -----------------------------------------------------------------------
resource "aws_rds_cluster" "dr" {
  provider = aws.dr

  cluster_identifier        = "${var.project}-${var.environment}-aurora-dr"
  global_cluster_identifier = aws_rds_global_cluster.main.id
  engine                    = "aurora-postgresql"
  engine_version            = var.engine_version

  db_subnet_group_name   = aws_db_subnet_group.dr.name
  vpc_security_group_ids = [var.dr_aurora_sg_id]

  storage_encrypted = true
  kms_key_id        = var.dr_kms_key_arn

  deletion_protection = var.deletion_protection
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.project}-${var.environment}-aurora-dr-final-snapshot"

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-aurora-dr"
  })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [replication_source_identifier, global_cluster_identifier]
  }

  depends_on = [aws_rds_cluster_instance.primary]
}

# -----------------------------------------------------------------------
# DR Cluster Instance (reduced capacity warm standby)
# -----------------------------------------------------------------------
resource "aws_rds_cluster_instance" "dr" {
  provider = aws.dr

  count = var.dr_instance_count

  identifier         = "${var.project}-${var.environment}-aurora-dr-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.dr.id
  instance_class     = var.dr_instance_class
  engine             = "aurora-postgresql"
  engine_version     = var.engine_version

  auto_minor_version_upgrade = false
  publicly_accessible        = false

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = var.dr_kms_key_arn
  performance_insights_retention_period = 7

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-aurora-dr-${count.index + 1}"
  })
}

# -----------------------------------------------------------------------
# Enhanced Monitoring Role
# -----------------------------------------------------------------------
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project}-${var.environment}-rds-enhanced-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
