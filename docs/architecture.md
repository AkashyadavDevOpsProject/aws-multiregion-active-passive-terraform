# Architecture Documentation

## Overview

Multi-region active-passive Disaster Recovery architecture for a financial-grade microservices application.

- **Primary:** ap-south-1 (Mumbai) — handles 100% of production traffic under normal operations
- **DR:** ap-south-2 (Hyderabad) — warm standby at reduced capacity, activated on failover

## Network topology

### VPC CIDR allocation

| Environment | Region | VPC CIDR |
|---|---|---|
| Production Primary | ap-south-1 | 10.0.0.0/16 |
| Production DR | ap-south-2 | 10.1.0.0/16 |
| Staging | ap-south-1 | 10.2.0.0/16 |

### Subnet tiers (per AZ, per VPC)

| Tier | CIDR example | Resources |
|---|---|---|
| Public | 10.0.1.0/24 | Public NLB, NAT Gateways |
| Private App | 10.0.11.0/24 | EKS nodes, Private ALB, DevOps EC2 |
| Private DB | 10.0.21.0/24 | Aurora, ElastiCache, Amazon MQ, EFS |

NAT Gateways are deployed one per AZ (3 total in production) for AZ-fault tolerance.

## Traffic flow

```
Users
  │
  ▼
Route 53 (active-passive failover)
  │
  ▼ (PRIMARY record → CloudFront distribution)
CloudFront (HTTP/2+3, HTTPS only)
  │   WAF WebACL: CRS + SQLi + bad-inputs + IP rate limit
  ▼
Public NLB (static IPs, ap-south-1a/b/c)
  │   TCP 443, target type: alb
  ▼
Private ALB (internal, path-based routing)
  │   TLS 1.3, HTTPS→HTTPS redirect
  ▼
EKS Pods (target type: ip, /26 ENI per node)
  │
  ├── Aurora PostgreSQL (writer: ap-south-1, reader: ap-south-2 via global cluster)
  ├── ElastiCache Redis (in-cluster, TLS required)
  ├── Amazon MQ (ActiveMQ, ACTIVE_STANDBY_MULTI_AZ)
  └── EFS (via EFS CSI driver, access points per service)
```

## DR failover procedure

1. **Detection:** Route 53 health check on primary NLB fails 3 times (≈90 seconds)
2. **DNS failover:** Route 53 shifts A/AAAA records to secondary (DR CloudFront)
3. **Aurora promotion** (manual):
   ```bash
   aws rds failover-global-cluster \
     --global-cluster-identifier swat-prod-aurora-global \
     --target-db-cluster-identifier swat-prod-dr-aurora-dr \
     --region ap-south-1
   ```
4. **DNS TTL:** Default TTL is 60 seconds — full traffic shift within ≈2.5 minutes of health check failure

**RTO target:** < 5 minutes (DNS propagation + Aurora promotion)
**RPO target:** < 30 seconds (Aurora Global DB typical lag + alarm threshold)

## Data replication

| Data store | Replication method | Direction | RPO |
|---|---|---|---|
| Aurora PostgreSQL | Aurora Global DB async replication | primary → DR | < 1s typical |
| ElastiCache Redis | Standalone in DR (no replication) | N/A | On failover: cold start |
| EFS | Independent file systems | N/A | On failover: empty |
| S3 app-assets | S3 Cross-Region Replication (async) | ap-south-1 → ap-south-2 | Minutes |
| S3 other buckets | Not replicated | N/A | N/A |

## IAM and security model

- All compute roles use AWS-managed policies where available
- Inline policies are scoped to the minimum required ARN prefix (project/environment prefix)
- IRSA: every EKS add-on and controller uses a dedicated role with the exact service account name and namespace in the `StringEquals` condition
- DevOps EC2: no SSH, no key pair — SSM Session Manager only
- GitHub CI/CD: OIDC provider scoped to repository + all branches; no long-lived keys

## Observability stack

| Tool | Deployment |
|---|---|
| CloudWatch | Native AWS — alarms, dashboards, log groups |
| X-Ray | Native AWS — distributed tracing, insights enabled |
| Prometheus | Helm release inside EKS (not Terraform-managed) |
| Grafana | Helm release inside EKS (not Terraform-managed) |

CloudWatch alarms page to the SNS topic created by the `observability` module. Prometheus/Grafana are deployed post-Terraform via the DevOps EC2 using Helm.
