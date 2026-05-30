variable "project" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region" {
  description = "AWS region where endpoints are created (used to construct service names)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID in which endpoints are created"
  type        = string
}

variable "private_app_subnet_ids" {
  description = "Subnet IDs where interface endpoint ENIs are placed"
  type        = list(string)
}

variable "private_app_route_table_ids" {
  description = "Map of AZ => route table ID for private app subnets (for gateway endpoint association)"
  type        = map(string)
}

variable "private_db_route_table_id" {
  description = "Route table ID for private DB subnets (for gateway endpoint association)"
  type        = string
}

variable "vpc_endpoints_sg_id" {
  description = "Security group ID applied to all interface endpoints"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
