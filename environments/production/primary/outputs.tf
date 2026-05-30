output "vpc_id" {
  description = "Primary VPC ID"
  value       = one(module.networking[*].vpc_id)
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = one(module.eks[*].cluster_name)
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = one(module.eks[*].cluster_endpoint)
  sensitive   = true
}

output "aurora_writer_endpoint" {
  description = "Aurora primary cluster writer endpoint"
  value       = one(module.aurora[*].primary_cluster_endpoint)
}

output "aurora_reader_endpoint" {
  description = "Aurora primary cluster reader endpoint"
  value       = one(module.aurora[*].primary_cluster_reader_endpoint)
}

output "aurora_secret_arn" {
  description = "Secrets Manager ARN for Aurora master credentials"
  value       = one(module.aurora[*].master_user_secret_arn)
  sensitive   = true
}

output "redis_primary_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = one(module.elasticache[*].primary_endpoint_address)
}

output "mq_amqp_endpoints" {
  description = "Amazon MQ AMQP endpoints"
  value       = one(module.amazon_mq[*].amqp_ssl_endpoints)
}

output "nlb_dns_name" {
  description = "Public NLB DNS name — needed by DR environment for Route 53 DR health check"
  value       = one(module.load_balancer[*].nlb_dns_name)
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name — needed by DR environment"
  value       = one(module.cloudfront[*].domain_name)
}

output "efs_file_system_id" {
  description = "EFS file system ID — configure in EKS StorageClass"
  value       = one(module.efs[*].file_system_id)
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions — set as AWS_ROLE_ARN in workflow"
  value       = one(module.iam[*].github_actions_terraform_role_arn)
}

output "irsa_lb_controller_role_arn" {
  description = "IRSA role ARN for AWS Load Balancer Controller"
  value       = one(module.eks[*].irsa_lb_controller_role_arn)
}

output "irsa_cluster_autoscaler_role_arn" {
  description = "IRSA role ARN for Cluster Autoscaler"
  value       = one(module.eks[*].irsa_cluster_autoscaler_role_arn)
}

# --- Cross-environment values (DR environment reads these via tfvars) ---

output "eks_cluster_role_arn" {
  description = "EKS cluster IAM role ARN — pass to DR environment as var.eks_cluster_role_arn"
  value       = one(module.iam[*].eks_cluster_role_arn)
}

output "eks_node_group_role_arn" {
  description = "EKS node group IAM role ARN — pass to DR environment as var.eks_node_group_role_arn"
  value       = one(module.iam[*].eks_node_group_role_arn)
}

output "devops_ec2_instance_profile_name" {
  description = "DevOps EC2 instance profile name — pass to DR environment"
  value       = one(module.iam[*].devops_ec2_instance_profile_name)
}

output "s3_replication_role_arn" {
  description = "S3 CRR IAM role ARN — pass to DR environment as var.s3_replication_role_arn"
  value       = one(module.iam[*].s3_replication_role_arn)
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID — pass to DR and staging environments"
  value       = one(module.route53[*].zone_id)
}
