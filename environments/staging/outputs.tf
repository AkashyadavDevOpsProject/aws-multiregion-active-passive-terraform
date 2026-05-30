output "vpc_id" { value = one(module.networking[*].vpc_id) }
output "eks_cluster_name" { value = one(module.eks[*].cluster_name) }
output "nlb_dns_name" { value = one(module.load_balancer[*].nlb_dns_name) }
output "cloudfront_domain_name" { value = one(module.cloudfront[*].domain_name) }
output "github_actions_role_arn" { value = one(module.iam[*].github_actions_terraform_role_arn) }
