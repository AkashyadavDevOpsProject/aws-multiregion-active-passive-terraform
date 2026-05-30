# Module: aurora

Provisions an Aurora Global Cluster with a primary writer cluster in ap-south-1 and a read-only secondary cluster in ap-south-2 (warm standby). Uses `manage_master_user_password = true` so RDS generates and rotates the master password in Secrets Manager — no passwords in Terraform state or .tf files.

## Architecture

```
Aurora Global Cluster
├── Primary (ap-south-1)
│   ├── Writer instance (db.r6g.large × 1)
│   └── Reader instance (db.r6g.large × 1)
└── Secondary/DR (ap-south-2)
    └── Reader instance (db.r6g.medium × 1) ← warm standby, smaller class
```

## Failover

Aurora Global Cluster failover is **not automated** in this architecture (active-passive). To promote the DR cluster:

```bash
aws rds failover-global-cluster \
  --global-cluster-identifier swat-production-aurora-global \
  --target-db-cluster-identifier swat-production-aurora-dr
```

## Security

- `deletion_protection = true` in production (enforced via variable)
- Storage encrypted with customer-managed KMS
- Master credentials via RDS-managed Secrets Manager (`manage_master_user_password = true`)
- `publicly_accessible = false` on all instances
- Enhanced Monitoring (60s interval) and Performance Insights enabled

## Provider requirements

Requires `aws.dr` provider alias for the secondary cluster:

```hcl
providers = {
  aws    = aws
  aws.dr = aws.dr
}
```

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `engine_version` | string | no | Default `"16.2"` |
| `database_name` | string | yes | Initial DB name |
| `master_username` | string | no | Default `"dbadmin"` |
| `deletion_protection` | bool | no | Default `true` |
| `primary_instance_count` | number | no | Default `2` (1 writer + 1 reader) |
| `dr_instance_count` | number | no | Default `1` (warm standby) |
| `primary_instance_class` | string | no | Default `db.r6g.large` |
| `dr_instance_class` | string | no | Default `db.r6g.medium` |

## Outputs

| Name | Description |
|---|---|
| `primary_cluster_endpoint` | Writer endpoint — app connection string |
| `primary_cluster_reader_endpoint` | Reader endpoint — read-scaling |
| `master_user_secret_arn` | Secrets Manager ARN — reference in app config |
