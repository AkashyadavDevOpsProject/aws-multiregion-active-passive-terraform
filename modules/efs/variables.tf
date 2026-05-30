variable "project" { type = string }
variable "environment" { type = string }

variable "performance_mode" {
  description = "EFS performance mode (generalPurpose or maxIO)"
  type        = string
  default     = "generalPurpose"
}

variable "throughput_mode" {
  description = "EFS throughput mode (bursting, provisioned, or elastic)"
  type        = string
  default     = "elastic"
}

variable "transition_to_ia" {
  description = "Lifecycle policy: days before transitioning to IA storage (e.g., AFTER_30_DAYS). Set null to disable."
  type        = string
  default     = "AFTER_30_DAYS"
}

variable "transition_to_primary_storage_class" {
  description = "Lifecycle policy: move accessed IA files back to standard (AFTER_1_ACCESS). Set null to disable."
  type        = string
  default     = "AFTER_1_ACCESS"
}

variable "db_subnet_ids" {
  description = "Subnet IDs for EFS mount targets (one per AZ, use private DB subnets)"
  type        = list(string)
}

variable "efs_sg_id" {
  description = "Security group ID for EFS mount targets (from security-groups module)"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for EFS encryption at rest"
  type        = string
}

variable "access_points" {
  description = "Map of EFS Access Point configurations. Key = access point name suffix."
  type = map(object({
    path        = string
    uid         = number
    gid         = number
    permissions = string
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
