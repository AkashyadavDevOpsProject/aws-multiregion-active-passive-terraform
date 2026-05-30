# Module: devops-ec2

Provisions a single DevOps EC2 instance managed by an Auto Scaling Group (desired=1). The instance has no inbound rules — all access is via SSM Session Manager. It carries `kubectl` and `helm` pre-installed via userdata for EKS operations.

## Design decisions

- **Launch Template** (not Launch Configuration) — LC is deprecated as of late 2023; LT supports IMDSv2, gp3 EBS, and instance refresh
- **ASG with desired=1** — provides automatic replacement if the instance terminates; use `min_size=0` to save cost in staging by scaling to 0
- **SSM-only access** — no SSH port, no key pair, no bastion required
- **IMDSv2 required** — `http_tokens = "required"` on all metadata requests
- **Encrypted EBS** — gp3 root volume encrypted with provided KMS key
- **AL2023** — AMI auto-resolved to latest Amazon Linux 2023 unless overridden

## Userdata (`userdata.sh.tpl`)

Installs on first boot:
- AWS CLI v2
- kubectl (version matches `kubernetes_version` from EKS module)
- Helm 3
- Configures kubeconfig for the EKS cluster via `aws eks update-kubeconfig`

## Usage

```hcl
module "devops_ec2" {
  source = "../../modules/devops-ec2"

  project               = var.project
  environment           = var.environment
  region                = var.region
  instance_type         = "t3.medium"
  subnet_id             = module.networking.private_app_subnet_ids_list[0]
  security_group_id     = module.security_groups.devops_ec2_sg_id
  instance_profile_name = module.iam.devops_ec2_instance_profile_name
  kms_key_arn           = aws_kms_key.main.arn
  eks_cluster_name      = module.eks.cluster_name

  tags = local.common_tags
}
```
