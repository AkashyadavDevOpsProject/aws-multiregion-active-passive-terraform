variable "project" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for the EKS control plane (from iam module)"
  type        = string
}

variable "node_group_role_arn" {
  description = "ARN of the IAM role for EKS managed node groups (from iam module)"
  type        = string
}

variable "private_app_subnet_ids" {
  description = "Subnet IDs for EKS node groups (private app tier)"
  type        = list(string)
}

variable "cluster_sg_id" {
  description = "Additional security group for the EKS cluster control plane (from security-groups module)"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt Kubernetes secrets at rest"
  type        = string
}

variable "endpoint_public_access" {
  description = "Enable public access to the EKS API server. Set false in production — access via DevOps EC2 or VPN only."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint (only relevant when endpoint_public_access = true)"
  type        = list(string)
  default     = []
}

variable "node_groups" {
  description = "Map of node group configurations. Key is the node group name suffix."
  type = map(object({
    instance_types  = list(string)
    capacity_type   = string
    desired_size    = number
    min_size        = number
    max_size        = number
    disk_size_gb    = number
    labels          = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
}

variable "addon_versions" {
  description = "Explicit version pins for EKS managed add-ons"
  type = object({
    coredns    = string
    kube_proxy = string
    vpc_cni    = string
    ebs_csi    = string
    efs_csi    = string
  })
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
