# Module: security-groups

Provisions all Security Groups for the architecture in a single module. Centralising SGs prevents the circular dependency problem that occurs when SG-A references SG-B and SG-B references SG-A (a common pattern when EKS nodes need to talk to the ALB and vice versa).

## Security groups created

| Name | Inbound | Purpose |
|---|---|---|
| `sg-nlb-public` | 443, 80 from `0.0.0.0/0` | Public NLB (only resource allowing 0.0.0.0/0) |
| `sg-alb-private` | 443, 80 from NLB SG | Private ALB |
| `sg-eks-cluster` | 443 from node SG | EKS control plane |
| `sg-eks-nodes` | self + 10250 from cluster + 8080/8443/30000-32767 from ALB | EKS worker nodes |
| `sg-devops-ec2` | None (SSM access only) | DevOps EC2 |
| `sg-aurora` | 5432 from nodes + devops EC2 | Aurora PostgreSQL |
| `sg-elasticache` | 6379 from nodes | ElastiCache Redis |
| `sg-amazon-mq` | 5671/61617 from nodes, 8162 from devops EC2 | Amazon MQ broker |
| `sg-efs` | 2049 from nodes | EFS mount targets |
| `sg-vpc-endpoints` | 443 from VPC CIDR | Interface VPC Endpoints |

## Security posture

- `0.0.0.0/0` ingress exists **only** on the public NLB SG, on port 443/80
- All other SGs reference specific source SGs — no CIDR-based ingress beyond the VPC CIDR for VPC endpoints
- DevOps EC2 has zero inbound rules — all access via SSM Session Manager

## Usage

```hcl
module "security_groups" {
  source = "../../modules/security-groups"

  project     = var.project
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  vpc_cidr    = var.vpc_cidr
  tags        = local.common_tags
}
```
