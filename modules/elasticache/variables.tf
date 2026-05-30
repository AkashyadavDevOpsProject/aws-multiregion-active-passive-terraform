variable "project" { type = string }
variable "environment" { type = string }

variable "node_type" {
  description = "ElastiCache node type (e.g., cache.r6g.large)"
  type        = string
  default     = "cache.r6g.large"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes in the replication group (1 = no HA, 2+ = Multi-AZ)"
  type        = number
  default     = 2
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "parameter_group_family" {
  description = "ElastiCache parameter group family"
  type        = string
  default     = "redis7"
}

variable "maxmemory_policy" {
  description = "Redis maxmemory eviction policy"
  type        = string
  default     = "allkeys-lru"
}

variable "snapshot_retention_days" {
  description = "Number of days to retain Redis snapshots"
  type        = number
  default     = 7
}

variable "db_subnet_ids" {
  description = "Subnet IDs for the ElastiCache subnet group (private DB subnets)"
  type        = list(string)
}

variable "elasticache_sg_id" {
  description = "Security group ID for ElastiCache (from security-groups module)"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for at-rest encryption"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
