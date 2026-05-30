variable "project" { type = string }
variable "environment" { type = string }

variable "kms_key_arn" {
  description = "KMS key ARN for backup vault encryption"
  type        = string
}

variable "backup_role_arn" {
  description = "IAM role ARN for AWS Backup (from iam module)"
  type        = string
}

variable "aurora_cluster_arns" {
  description = "ARNs of Aurora clusters to include in backup selection"
  type        = list(string)
  default     = []
}

variable "efs_file_system_arns" {
  description = "ARNs of EFS file systems to include in backup selection"
  type        = list(string)
  default     = []
}

variable "daily_retention_days" {
  description = "Days to retain daily backups"
  type        = number
  default     = 14
}

variable "weekly_retention_days" {
  description = "Days to retain weekly backups"
  type        = number
  default     = 60
}

variable "monthly_retention_days" {
  description = "Days to retain monthly backups (moves to cold storage after 30 days)"
  type        = number
  default     = 365
}

variable "enable_vault_lock" {
  description = "Enable AWS Backup Vault Lock (WORM protection). Cannot be undone after changeable_for_days expires."
  type        = bool
  default     = false
}

variable "vault_lock_min_retention_days" {
  type    = number
  default = 7
}

variable "vault_lock_max_retention_days" {
  type    = number
  default = 365
}

variable "vault_lock_changeable_days" {
  description = "Grace period in days during which the vault lock config can be changed"
  type        = number
  default     = 3
}

variable "alarm_sns_topic_arns" {
  description = "SNS topic ARNs to notify on backup job failures"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
