# Module: efs

Provisions an EFS file system with mount targets in each DB subnet AZ, access points per consuming application, and lifecycle policies for cost management.

## Access Points

Pass a map of access points keyed by app name:

```hcl
access_points = {
  app-shared = {
    path        = "/shared"
    uid         = 1000
    gid         = 1000
    permissions = "755"
  }
}
```

The EFS CSI Driver uses access point IDs in its `StorageClass` definition.

## Usage

```hcl
module "efs" {
  source = "../../modules/efs"

  project        = var.project
  environment    = var.environment
  db_subnet_ids  = module.networking.private_db_subnet_ids_list
  efs_sg_id      = module.security_groups.efs_sg_id
  kms_key_arn    = aws_kms_key.main.arn
  access_points  = var.efs_access_points
  tags           = local.common_tags
}
```
