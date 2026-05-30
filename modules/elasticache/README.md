# Module: elasticache

Provisions an ElastiCache Redis replication group in Multi-AZ configuration for application caching.

## Security

- In-transit encryption: TLS required (`transit_encryption_mode = "required"`)
- At-rest encryption: KMS customer-managed key
- No public access — placed in private DB subnets

## Usage

```hcl
module "elasticache" {
  source = "../../modules/elasticache"

  project           = var.project
  environment       = var.environment
  node_type         = "cache.r6g.large"
  num_cache_nodes   = 2
  db_subnet_ids     = module.networking.private_db_subnet_ids_list
  elasticache_sg_id = module.security_groups.elasticache_sg_id
  kms_key_arn       = aws_kms_key.main.arn
  tags              = local.common_tags
}
```
