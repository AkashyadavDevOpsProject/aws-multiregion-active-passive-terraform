variable "project" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID in which all security groups are created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC — used to scope VPC Endpoint SG ingress"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
