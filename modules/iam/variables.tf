variable "project" {
  description = "Project name prefix for all resource names and tags"
  type        = string
}

variable "environment" {
  description = "Deployment environment (production, staging)"
  type        = string
}

variable "account_id" {
  description = "AWS account ID — used to scope IAM policy resource ARNs"
  type        = string
}

variable "github_org" {
  description = "GitHub organisation or username that owns the Terraform repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name — OIDC trust policy is scoped to this repo"
  type        = string
}

variable "terraform_state_bucket" {
  description = "S3 bucket name that holds Terraform remote state"
  type        = string
}

variable "terraform_lock_table" {
  description = "DynamoDB table name used for Terraform state locking"
  type        = string
}

variable "s3_source_bucket_arns" {
  description = "ARNs of S3 buckets in ap-south-1 that are replicated (source side of CRR)"
  type        = list(string)
  default     = []
}

variable "s3_destination_bucket_arns" {
  description = "ARNs of S3 buckets in ap-south-2 that receive replicated objects (destination side of CRR)"
  type        = list(string)
  default     = []
}

variable "s3_source_kms_key_arns" {
  description = "ARNs of KMS keys used to encrypt source S3 buckets (for CRR KMS decrypt permission)"
  type        = list(string)
  default     = []
}

variable "s3_destination_kms_key_arns" {
  description = "ARNs of KMS keys used to encrypt destination S3 buckets (for CRR KMS encrypt permission)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags applied to all resources in this module"
  type        = map(string)
  default     = {}
}
