variable "project" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "primary_region" {
  description = "AWS region for the primary VPC (e.g., ap-south-1)"
  type        = string
}

variable "dr_region" {
  description = "AWS region for the DR VPC (e.g., ap-south-2)"
  type        = string
}

variable "amazon_side_asn" {
  description = "BGP ASN for the primary TGW (must be unique across connected TGWs)"
  type        = number
  default     = 64512
}

variable "dr_amazon_side_asn" {
  description = "BGP ASN for the DR TGW"
  type        = number
  default     = 64513
}

variable "primary_vpc_id" {
  description = "VPC ID in the primary region to attach to TGW"
  type        = string
}

variable "primary_vpc_cidr" {
  description = "CIDR block of the primary VPC — used for DR→primary TGW route"
  type        = string
}

variable "primary_private_app_subnet_ids" {
  description = "Subnet IDs in the primary VPC for the TGW VPC attachment"
  type        = list(string)
}

variable "dr_vpc_id" {
  description = "VPC ID in the DR region to attach to DR TGW"
  type        = string
}

variable "dr_vpc_cidr" {
  description = "CIDR block of the DR VPC — used for primary→DR TGW route"
  type        = string
}

variable "dr_private_app_subnet_ids" {
  description = "Subnet IDs in the DR VPC for the TGW VPC attachment"
  type        = list(string)
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
