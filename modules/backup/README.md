# Module: backup

Provisions an AWS Backup vault, plan (daily/weekly/monthly), and resource selections for Aurora and EFS. The SNS alarm fires when any backup job fails.

## Retention schedule

| Backup | Schedule | Retention |
|---|---|---|
| Daily | 01:00 UTC | 14 days |
| Weekly | Sunday 02:00 UTC | 60 days |
| Monthly | 1st of month 03:00 UTC | 365 days (cold storage after 30d) |

## Vault Lock

`enable_vault_lock = false` by default (WORM protection). Set to `true` in production after confirming retention requirements — cannot be reversed once `changeable_for_days` expires.
