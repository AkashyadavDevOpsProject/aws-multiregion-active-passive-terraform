output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint URL of the EKS API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64-encoded certificate authority data for the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version running on the cluster"
  value       = aws_eks_cluster.main.version
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA — used when attaching additional IRSA roles outside this module"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL (without https://) — used in IAM condition keys"
  value       = local.oidc_provider_url
}

output "irsa_lb_controller_role_arn" {
  description = "ARN of the IRSA role for the AWS Load Balancer Controller"
  value       = aws_iam_role.irsa_lb_controller.arn
}

output "irsa_cluster_autoscaler_role_arn" {
  description = "ARN of the IRSA role for the Cluster Autoscaler"
  value       = aws_iam_role.irsa_cluster_autoscaler.arn
}

output "irsa_ebs_csi_role_arn" {
  description = "ARN of the IRSA role for the EBS CSI Driver"
  value       = aws_iam_role.irsa_ebs_csi.arn
}

output "irsa_efs_csi_role_arn" {
  description = "ARN of the IRSA role for the EFS CSI Driver"
  value       = aws_iam_role.irsa_efs_csi.arn
}

output "node_group_names" {
  description = "Map of node group key => full AWS node group name"
  value       = { for k, ng in aws_eks_node_group.main : k => ng.node_group_name }
}
