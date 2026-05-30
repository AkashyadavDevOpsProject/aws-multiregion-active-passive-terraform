# Module: observability

Provisions CloudWatch log groups, dashboards, alarms, X-Ray group, and SNS topic for the observability stack.

## Alarms

| Alarm | Threshold | Trigger |
|---|---|---|
| EKS node CPU | ≥ 80% for 15 min | Scale out or investigate |
| Aurora CPU | ≥ 80% for 15 min | Scaling or query tuning |
| Aurora replication lag | ≥ 30s | DR RPO breach risk |
| ElastiCache CPU | ≥ 70% for 15 min | Memory/eviction risk |
| AWS Backup job failures | ≥ 1 per day | Backup broken |

All alarms route to the SNS topic created by this module. Pass `alarm_email_endpoints` to subscribe email addresses.

## Prometheus/Grafana

Prometheus and Grafana run as Helm releases inside EKS (not managed by Terraform). The EKS module's IRSA outputs provide the necessary roles. Deploy them post-`terraform apply` via the DevOps EC2 using `helm install`.
