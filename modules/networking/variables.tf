variable "project" {
  description = "Project name prefix for all resource names and tags"
  type        = string
}

variable "environment" {
  description = "Deployment environment (production, staging)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of AZs to deploy subnets into (e.g., [\"ap-south-1a\", \"ap-south-1b\", \"ap-south-1c\"])"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets — one per AZ in the same order as availability_zones"
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private app subnets (EKS nodes, ALB) — one per AZ"
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private DB subnets (Aurora, ElastiCache, MQ, EFS) — one per AZ"
  type        = list(string)
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID to add as a route in private route tables. Set to null if TGW is not yet attached."
  type        = string
  default     = null
}

variable "tgw_destination_cidr" {
  description = "Destination CIDR for the Transit Gateway route (e.g., the DR VPC CIDR range)"
  type        = string
  default     = null
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "CloudWatch log group retention in days for VPC Flow Logs"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Common tags applied to all resources in this module"
  type        = map(string)
  default     = {}
}
