variable "project" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region" {
  description = "AWS region where the DevOps EC2 is deployed"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the DevOps instance"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID override. Leave null to use the latest Amazon Linux 2023."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Private app subnet ID to place the DevOps EC2 in"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the DevOps EC2 (from security-groups module)"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name to attach (from iam module)"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for EBS volume encryption"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name — used in userdata to configure kubectl"
  type        = string
}

variable "root_volume_size_gb" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
