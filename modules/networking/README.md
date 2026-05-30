# Module: networking

Provisions the VPC and all subnetting for a single region. This module is instantiated once per region (ap-south-1 primary, ap-south-2 DR).

## Subnet layout (per AZ)

| Subnet tier | Route target | Resources |
|---|---|---|
| `public` | Internet Gateway | Public NLB, NAT Gateways |
| `private-app` | NAT GW (per AZ) + TGW | EKS node groups, private ALB, DevOps EC2 |
| `private-db` | TGW only (no NAT) | Aurora, ElastiCache, Amazon MQ, EFS |

## HA design

- One NAT Gateway per AZ — private app subnets always egress via their AZ-local NAT GW, surviving an AZ failure
- DB subnets have no NAT GW route — database tier has no outbound internet access

## Transit Gateway

Pass `transit_gateway_id` and `tgw_destination_cidr` to add TGW routes to private route tables. Leave both `null` when provisioning the VPC before the TGW module runs; a subsequent `terraform apply` after TGW is attached adds the routes.

## VPC Flow Logs

Enabled by default (`enable_flow_logs = true`) — logs to CloudWatch Logs. Set retention via `flow_logs_retention_days` (default 90 days).

## EKS subnet tags

Public and private-app subnets carry the standard `kubernetes.io/role/elb` and `kubernetes.io/role/internal-elb` tags so the AWS Load Balancer Controller can auto-discover subnets.

## Usage

```hcl
module "networking" {
  source = "../../modules/networking"

  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr

  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs

  transit_gateway_id   = module.transit_gateway.tgw_id
  tgw_destination_cidr = var.dr_vpc_cidr

  tags = local.common_tags
}
```

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `project` | string | yes | Project name prefix |
| `environment` | string | yes | Environment name |
| `vpc_cidr` | string | yes | VPC CIDR (e.g., `10.0.0.0/16`) |
| `availability_zones` | list(string) | yes | AZ names |
| `public_subnet_cidrs` | list(string) | yes | One per AZ |
| `private_app_subnet_cidrs` | list(string) | yes | One per AZ |
| `private_db_subnet_cidrs` | list(string) | yes | One per AZ |
| `transit_gateway_id` | string | no | TGW ID for cross-region routing |
| `tgw_destination_cidr` | string | no | CIDR to route via TGW |
| `enable_flow_logs` | bool | no | Default `true` |
| `flow_logs_retention_days` | number | no | Default `90` |
| `tags` | map(string) | no | Common tags |

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | Used by all other modules |
| `public_subnet_ids_list` | NLB, NAT GW placement |
| `private_app_subnet_ids_list` | EKS node groups, ALB |
| `private_db_subnet_ids_list` | Aurora, ElastiCache, MQ, EFS |
| `nat_gateway_ids` | Referenced by TGW module |
| `private_app_route_table_ids` | Used by vpc-endpoints module |
| `private_db_route_table_id` | Used by vpc-endpoints module |
