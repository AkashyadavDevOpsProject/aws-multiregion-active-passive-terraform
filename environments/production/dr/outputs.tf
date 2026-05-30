output "vpc_id" {
  value = one(module.networking[*].vpc_id)
}

output "eks_cluster_name" {
  value = one(module.eks[*].cluster_name)
}

output "nlb_dns_name" {
  description = "DR NLB DNS name — feed back into primary environment as var.dr_nlb_dns_name"
  value       = one(module.load_balancer[*].nlb_dns_name)
}

output "cloudfront_domain_name" {
  description = "DR CloudFront domain — feed back into primary environment as var.dr_cloudfront_domain_name"
  value       = one(module.cloudfront[*].domain_name)
}

output "efs_file_system_id" {
  value = one(module.efs[*].file_system_id)
}
