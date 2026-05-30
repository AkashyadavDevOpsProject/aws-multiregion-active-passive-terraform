# Module: iam

Provisions all IAM roles used across the architecture. IRSA (IAM Roles for Service Accounts) roles for EKS add-ons are intentionally **not** in this module — they are created inside the `eks` module after the OIDC provider URL is known, to avoid a circular dependency.

## Roles created

| Role | Trust Principal | Purpose |
|---|---|---|
| `eks-cluster-role` | `eks.amazonaws.com` | EKS control plane |
| `eks-node-role` | `ec2.amazonaws.com` | EKS managed node groups |
| `devops-ec2-role` | `ec2.amazonaws.com` | DevOps EC2 (SSM, ECR, EKS, Secrets Manager) |
| `s3-replication-role` | `s3.amazonaws.com` | S3 CRR source-to-destination replication |
| `backup-role` | `backup.amazonaws.com` | AWS Backup vault operations |
| `github-actions-terraform-role` | GitHub OIDC | Terraform plan/apply in CI/CD |

## GitHub OIDC

The module creates `aws_iam_openid_connect_provider` for `token.actions.githubusercontent.com`. The Terraform deployment role trusts the configured `github_org/github_repo` with wildcard branch/ref matching. No `AWS_ACCESS_KEY_ID` is stored in GitHub — the workflow uses `aws-actions/configure-aws-credentials` with `role-to-assume`.

## Usage

```hcl
module "iam" {
  source = "../../modules/iam"

  project        = var.project
  environment    = var.environment
  account_id     = data.aws_caller_identity.current.account_id
  github_org     = var.github_org
  github_repo    = var.github_repo

  terraform_state_bucket = var.terraform_state_bucket
  terraform_lock_table   = var.terraform_lock_table

  s3_source_bucket_arns      = module.s3.source_bucket_arns
  s3_destination_bucket_arns = module.s3.destination_bucket_arns

  tags = local.common_tags
}
```

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `project` | string | yes | Project name prefix |
| `environment` | string | yes | Environment name |
| `account_id` | string | yes | AWS account ID for scoping ARNs |
| `github_org` | string | yes | GitHub org/username for OIDC trust |
| `github_repo` | string | yes | GitHub repo name for OIDC trust |
| `terraform_state_bucket` | string | yes | S3 bucket for Terraform state |
| `terraform_lock_table` | string | yes | DynamoDB table for state locking |
| `s3_source_bucket_arns` | list(string) | no | Source bucket ARNs for CRR role |
| `s3_destination_bucket_arns` | list(string) | no | Destination bucket ARNs for CRR role |
| `s3_source_kms_key_arns` | list(string) | no | KMS key ARNs for source bucket decryption |
| `s3_destination_kms_key_arns` | list(string) | no | KMS key ARNs for destination bucket encryption |
| `tags` | map(string) | no | Additional tags merged on all resources |

## Outputs

| Name | Description |
|---|---|
| `eks_cluster_role_arn` | Passed to `eks` module `cluster_role_arn` |
| `eks_node_group_role_arn` | Passed to `eks` module `node_group_role_arn` |
| `eks_node_group_role_name` | Used to attach additional managed policies to nodes |
| `devops_ec2_instance_profile_name` | Passed to `devops-ec2` module |
| `s3_replication_role_arn` | Passed to `s3` module for CRR configuration |
| `backup_role_arn` | Passed to `backup` module |
| `github_actions_terraform_role_arn` | Set as `AWS_ROLE_ARN` in GitHub Actions workflows |
