# Module: s3

Provisions S3 buckets in both regions with mandatory security controls and cross-region replication for `app_assets`.

## Buckets created (per region)

| Bucket key | Purpose |
|---|---|
| `app-assets` | Application static assets (replicated primary → DR) |
| `access-logs` | ALB/NLB/CloudFront access logs (90-day expiry) |
| `tf-artifacts` | Terraform plan artifacts for CI/CD |

## Mandatory controls on all buckets

- Versioning: Enabled
- Encryption: SSE-KMS (customer-managed key)
- Public access: All four block-public-access controls enabled
- Non-current version expiry: 90 days (except access-logs)

## CRR

`app_assets` only. Uses the replication role from the `iam` module. Replicated objects are encrypted with the DR region KMS key.
