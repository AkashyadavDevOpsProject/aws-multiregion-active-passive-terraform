output "nlb_public_sg_id" {
  description = "Security group ID for the public NLB"
  value       = aws_security_group.nlb_public.id
}

output "alb_private_sg_id" {
  description = "Security group ID for the private ALB"
  value       = aws_security_group.alb_private.id
}

output "eks_cluster_sg_id" {
  description = "Security group ID for the EKS control plane"
  value       = aws_security_group.eks_cluster.id
}

output "eks_nodes_sg_id" {
  description = "Security group ID for EKS worker nodes"
  value       = aws_security_group.eks_nodes.id
}

output "devops_ec2_sg_id" {
  description = "Security group ID for the DevOps EC2 instance"
  value       = aws_security_group.devops_ec2.id
}

output "aurora_sg_id" {
  description = "Security group ID for Aurora PostgreSQL"
  value       = aws_security_group.aurora.id
}

output "elasticache_sg_id" {
  description = "Security group ID for ElastiCache Redis"
  value       = aws_security_group.elasticache.id
}

output "amazon_mq_sg_id" {
  description = "Security group ID for Amazon MQ broker"
  value       = aws_security_group.amazon_mq.id
}

output "efs_sg_id" {
  description = "Security group ID for EFS mount targets"
  value       = aws_security_group.efs.id
}

output "vpc_endpoints_sg_id" {
  description = "Security group ID for Interface VPC Endpoints"
  value       = aws_security_group.vpc_endpoints.id
}
