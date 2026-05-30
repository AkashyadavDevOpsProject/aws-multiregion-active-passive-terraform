# Module: vpc-endpoints

Provisions all VPC Endpoints needed to eliminate internet traffic for AWS API calls. This is the zero-trust networking layer — EKS pods pull images from ECR, ship logs to CloudWatch, exchange IRSA tokens with STS, and read secrets from Secrets Manager all without leaving the AWS network.

## Endpoints created

### Interface Endpoints (ENI-based, billable)

| Endpoint | Purpose |
|---|---|
| `ecr.api` | Pull image manifests |
| `ecr.dkr` | Pull image layers |
| `eks` | EKS API private access |
| `sts` | IRSA token exchange |
| `ssm` | SSM Session Manager |
| `ssmmessages` | SSM data channel |
| `ec2messages` | SSM agent comms |
| `secretsmanager` | Secret retrieval by apps |
| `logs` | CloudWatch Logs |
| `monitoring` | CloudWatch Metrics |
| `xray` | X-Ray traces |
| `elasticloadbalancing` | LB controller operations |
| `autoscaling` | Cluster Autoscaler |

### Gateway Endpoints (free, route-table-based)

| Endpoint | Purpose |
|---|---|
| `s3` | S3 bucket access, ECR layer storage |
| `dynamodb` | Terraform state lock table |

## Usage

```hcl
module "vpc_endpoints" {
  source = "../../modules/vpc-endpoints"

  project     = var.project
  environment = var.environment
  region      = var.region
  vpc_id      = module.networking.vpc_id

  private_app_subnet_ids      = module.networking.private_app_subnet_ids_list
  private_app_route_table_ids = module.networking.private_app_route_table_ids
  private_db_route_table_id   = module.networking.private_db_route_table_id
  vpc_endpoints_sg_id         = module.security_groups.vpc_endpoints_sg_id

  tags = local.common_tags
}
```
