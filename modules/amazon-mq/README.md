# Module: amazon-mq

Provisions an Amazon MQ broker (ActiveMQ, ACTIVE_STANDBY_MULTI_AZ). Broker admin credentials are sourced from Secrets Manager at plan time — never stored in Terraform state or .tf files.

## Credentials

Create the secret in Secrets Manager before running `terraform apply`:

```json
{
  "username": "app-user",
  "password": "<strong-password>",
  "admin_username": "admin",
  "admin_password": "<strong-password>"
}
```

Pass the secret ID as `mq_admin_secret_id`.

## Security

- `publicly_accessible = false` — accessible only from EKS node SG and DevOps EC2 SG
- Storage encrypted with KMS
- AMQP+SSL on port 5671, OpenWire+SSL on port 61617

## Usage

```hcl
module "amazon_mq" {
  source = "../../modules/amazon-mq"

  project            = var.project
  environment        = var.environment
  db_subnet_ids      = module.networking.private_db_subnet_ids_list
  amazon_mq_sg_id    = module.security_groups.amazon_mq_sg_id
  kms_key_arn        = aws_kms_key.main.arn
  mq_admin_secret_id = "swat/production/amazon-mq/admin"
  tags               = local.common_tags
}
```
