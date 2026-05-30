variable "project" { type = string }
variable "environment" { type = string }

variable "engine_type" {
  description = "MQ broker engine type (ActiveMQ or RabbitMQ)"
  type        = string
  default     = "ActiveMQ"
}

variable "engine_version" {
  description = "MQ broker engine version"
  type        = string
  default     = "5.17.6"
}

variable "deployment_mode" {
  description = "MQ deployment mode (SINGLE_INSTANCE or ACTIVE_STANDBY_MULTI_AZ)"
  type        = string
  default     = "ACTIVE_STANDBY_MULTI_AZ"
}

variable "host_instance_type" {
  description = "MQ broker instance type"
  type        = string
  default     = "mq.m5.large"
}

variable "db_subnet_ids" {
  description = "Subnet IDs for the MQ broker (2 subnets required for ACTIVE_STANDBY_MULTI_AZ)"
  type        = list(string)
}

variable "amazon_mq_sg_id" {
  description = "Security group ID for Amazon MQ (from security-groups module)"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for broker storage encryption"
  type        = string
}

variable "mq_admin_secret_id" {
  description = "Secrets Manager secret ID containing MQ admin credentials (keys: username, password, admin_username, admin_password)"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
