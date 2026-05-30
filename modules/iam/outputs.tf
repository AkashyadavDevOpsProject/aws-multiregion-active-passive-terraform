output "eks_cluster_role_arn" {
  description = "ARN of the IAM role assumed by the EKS control plane"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_group_role_arn" {
  description = "ARN of the IAM role assumed by EKS managed node group EC2 instances"
  value       = aws_iam_role.eks_node_group.arn
}

output "eks_node_group_role_name" {
  description = "Name of the EKS node group IAM role — used when attaching additional policies"
  value       = aws_iam_role.eks_node_group.name
}

output "devops_ec2_role_arn" {
  description = "ARN of the IAM role assumed by the DevOps EC2 instance"
  value       = aws_iam_role.devops_ec2.arn
}

output "devops_ec2_instance_profile_name" {
  description = "Name of the IAM instance profile attached to the DevOps EC2 — passed to the devops-ec2 module"
  value       = aws_iam_instance_profile.devops_ec2.name
}

output "s3_replication_role_arn" {
  description = "ARN of the IAM role used by S3 for cross-region replication — passed to the s3 module"
  value       = aws_iam_role.s3_replication.arn
}

output "backup_role_arn" {
  description = "ARN of the IAM role assumed by AWS Backup — passed to the backup module"
  value       = aws_iam_role.backup.arn
}

output "github_actions_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider — referenced in GitHub Actions workflow trust policies"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

output "github_actions_terraform_role_arn" {
  description = "ARN of the IAM role assumed by GitHub Actions for Terraform plan/apply — set as AWS_ROLE_ARN in workflow"
  value       = aws_iam_role.github_actions_terraform.arn
}
