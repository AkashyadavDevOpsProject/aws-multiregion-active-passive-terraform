variable "project" { type = string }
variable "environment" { type = string }

variable "account_id" {
  description = "AWS account ID — used to construct globally unique bucket names"
  type        = string
}

variable "primary_region" {
  description = "Primary region for source buckets (e.g., ap-south-1)"
  type        = string
}

variable "dr_region" {
  description = "DR region for destination buckets (e.g., ap-south-2)"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for primary region bucket encryption"
  type        = string
}

variable "dr_kms_key_arn" {
  description = "KMS key ARN for DR region bucket encryption"
  type        = string
}

variable "s3_replication_role_arn" {
  description = "IAM role ARN for S3 CRR (from iam module)"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
