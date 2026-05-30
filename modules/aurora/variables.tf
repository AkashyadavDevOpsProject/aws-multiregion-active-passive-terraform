variable "project" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region (e.g., ap-south-1)"
  type        = string
}

variable "dr_region" {
  description = "DR AWS region (e.g., ap-south-2)"
  type        = string
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version (e.g., 15.4)"
  type        = string
  default     = "16.2"
}

variable "parameter_group_family" {
  description = "Aurora parameter group family (e.g., aurora-postgresql16)"
  type        = string
  default     = "aurora-postgresql16"
}

variable "database_name" {
  description = "Name of the initial database created in the cluster"
  type        = string
}

variable "master_username" {
  description = "Master username for the Aurora cluster"
  type        = string
  default     = "dbadmin"
}

variable "primary_db_subnet_ids" {
  description = "Subnet IDs for Aurora subnet group in primary region"
  type        = list(string)
}

variable "dr_db_subnet_ids" {
  description = "Subnet IDs for Aurora subnet group in DR region"
  type        = list(string)
}

variable "aurora_sg_id" {
  description = "Security group ID for Aurora in primary region"
  type        = string
}

variable "dr_aurora_sg_id" {
  description = "Security group ID for Aurora in DR region"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for Aurora encryption in primary region"
  type        = string
}

variable "dr_kms_key_arn" {
  description = "KMS key ARN for Aurora encryption in DR region"
  type        = string
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Enable deletion protection on the cluster. Must be true in production."
  type        = bool
  default     = true
}

variable "primary_instance_count" {
  description = "Number of Aurora instances in the primary cluster (writer + readers)"
  type        = number
  default     = 2
}

variable "primary_instance_class" {
  description = "Instance class for primary Aurora instances (e.g., db.r6g.large)"
  type        = string
  default     = "db.r6g.large"
}

variable "dr_instance_count" {
  description = "Number of Aurora instances in the DR cluster (warm standby — typically 1)"
  type        = number
  default     = 1
}

variable "dr_instance_class" {
  description = "Instance class for DR Aurora instances — smaller for cost (e.g., db.r6g.medium)"
  type        = string
  default     = "db.r6g.medium"
}

variable "rds_monitoring_role_arn" {
  description = "Unused — module creates its own Enhanced Monitoring role internally. Kept for backwards compatibility."
  type        = string
  default     = ""
}

variable "dr_rds_monitoring_role_arn" {
  description = "Unused — module creates its own Enhanced Monitoring role internally. Kept for backwards compatibility."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
