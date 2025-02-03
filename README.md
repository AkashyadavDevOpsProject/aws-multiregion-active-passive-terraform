# terraform-active-passive-dr-infrastructurer

Production-grade Terraform IaC for a multi-region active-passive Disaster Recovery architecture on AWS — built for a financial-grade microservices application.

<img width="2461" height="1491" alt="AWSINFRA drawio" src="https://github.com/user-attachments/assets/9ce82c64-20aa-4cb4-9207-1a0828e5c979" />




| | |
|---|---|
| **Primary region** | ap-south-1 (Mumbai) — active |
| **DR region** | ap-south-2 (Hyderabad) — warm standby |
| **Terraform** | >= 1.6.0 |
| **AWS Provider** | ~> 5.0 |
| **EKS** | 1.34 |
| **State backend** | S3 + DynamoDB lock |
| **CI/CD auth** | GitHub OIDC (no stored AWS keys) |

---

## Architecture overview

```
                         ┌─────────────────────────────────────────────────┐
                         │              AWS — ap-south-1 (Primary)         │
Users ──► Route 53 ──────┤                                                 │
  (failover routing)     │  CloudFront ──► WAF ──► NLB ──► ALB ──► EKS   │
                         │                                                 │
                         │  Aurora Global DB (writer)   ElastiCache Redis │
                         │  Amazon MQ (ActiveMQ)        EFS                │
                         │  S3 (CRR source)             AWS Backup         │
                         │  Transit Gateway ◄──────────────────────────┐  │
                         └─────────────────────────────────────────────┼──┘
                                                                        │
                         ┌─────────────────────────────────────────────┼──┐
                         │              AWS — ap-south-2 (DR)          │  │
                         │                                             TGW │
                         │  CloudFront ──► WAF ──► NLB ──► ALB ──► EKS   │
                         │                                                 │
                         │  Aurora Global DB (reader, promoted on DR)      │
                         │  ElastiCache Redis (standalone)                 │
                         │  EFS (independent)                              │
                         │  S3 (CRR destination)                           │
                         └─────────────────────────────────────────────────┘
```

**Traffic flow (normal):** Users → Route 53 (Primary) → CloudFront → WAF → Public NLB → Private ALB → EKS pods

**Failover trigger:** Route 53 health check on primary NLB fails 3 consecutive times → DNS shifts to DR CloudFront automatically.

---

## Repository structure

```
terraform-swat-aws-dr/
├── README.md
├── DECISIONS.md
├── .github/workflows/
│   ├── terraform-plan.yml    # Runs on PR — plans all changed environments
│   └── terraform-apply.yml   # Runs on main merge — applies with env protection gates
├── docs/
│   └── architecture.md
├── modules/
│   ├── acm/                  # ACM certs: primary region + us-east-1 (CloudFront)
│   ├── iam/                  # All IAM roles, GitHub OIDC provider
│   ├── networking/           # VPC, subnets, IGW, NAT GW, route tables, flow logs
│   ├── transit-gateway/      # TGW pair + peering (ap-south-1 ↔ ap-south-2)
│   ├── security-groups/      # All SGs in one module (prevents circular deps)
│   ├── vpc-endpoints/        # Interface + Gateway endpoints (zero-trust networking)
│   ├── eks/                  # EKS 1.34, node groups, add-ons, IRSA roles
│   ├── devops-ec2/           # DevOps EC2 (Launch Template + ASG, SSM only)
│   ├── aurora/               # Aurora Global DB (PostgreSQL, active-passive)
│   ├── elasticache/          # ElastiCache Redis (Multi-AZ replication group)
│   ├── amazon-mq/            # Amazon MQ (ActiveMQ, ACTIVE_STANDBY_MULTI_AZ)
│   ├── efs/                  # EFS file system, mount targets, access points
│   ├── load-balancer/        # Public NLB → Private ALB → EKS (NLB-to-ALB chaining)
│   ├── cloudfront/           # CloudFront distribution + WAF WebACL (us-east-1)
│   ├── route53/              # Health checks + active-passive failover records
│   ├── s3/                   # S3 buckets + CRR (ap-south-1 → ap-south-2)
│   ├── backup/               # AWS Backup vault + daily/weekly/monthly plan
│   └── observability/        # CloudWatch alarms/dashboards, X-Ray, SNS
└── environments/
    ├── production/
    │   ├── primary/          # ap-south-1 — state: statesave/prod-primary/state.tfstate
    │   └── dr/               # ap-south-2 — state: statesave/prod-dr/state.tfstate
    └── staging/              # ap-south-1 — state: statesave/staging/state.tfstate
```

---

## Modules

| Module | Description |
|---|---|
| [acm](modules/acm/README.md) | ACM certificates with DNS validation (primary + us-east-1 for CloudFront) |
| [iam](modules/iam/README.md) | EKS cluster/node roles, DevOps EC2, S3 CRR, Backup, GitHub OIDC |
| [networking](modules/networking/README.md) | VPC with 3-tier subnets (public, private-app, private-db), NAT per AZ, flow logs |
| [transit-gateway](modules/transit-gateway/README.md) | TGW pair with peering and explicit route tables |
| [security-groups](modules/security-groups/README.md) | All SGs centralised; only NLB allows 0.0.0.0/0 on 443 |
| [vpc-endpoints](modules/vpc-endpoints/README.md) | 13 interface endpoints + S3/DynamoDB gateway endpoints |
| [eks](modules/eks/README.md) | EKS 1.34, managed node groups with IMDSv2/gp3/KMS, 5 IRSA roles |
| [devops-ec2](modules/devops-ec2/README.md) | SSM-only DevOps box with kubectl + helm, ASG-managed |
| [aurora](modules/aurora/README.md) | Aurora Global PostgreSQL — writer + reader primary, warm standby DR |
| [elasticache](modules/elasticache/README.md) | Redis 7.1, Multi-AZ, TLS required, KMS encrypted |
| [amazon-mq](modules/amazon-mq/README.md) | ActiveMQ ACTIVE_STANDBY_MULTI_AZ, credentials from Secrets Manager |
| [efs](modules/efs/README.md) | EFS Standard with lifecycle policies and per-app access points |
| [load-balancer](modules/load-balancer/README.md) | NLB-to-ALB chaining, TLS 1.3, HTTPS-only, deletion protection |
| [cloudfront](modules/cloudfront/README.md) | CloudFront + WAF (CRS + SQLi + known-bad-inputs + IP rate limit) |
| [route53](modules/route53/README.md) | Active-passive failover with health checks on both NLBs |
| [s3](modules/s3/README.md) | Versioned, KMS-encrypted, public-access-blocked, CRR to DR |
| [backup](modules/backup/README.md) | Daily/weekly/monthly backup with vault lock option |
| [observability](modules/observability/README.md) | CloudWatch alarms for EKS, Aurora lag, Redis, backup failures |

---

## Getting started

### Prerequisites

- Terraform >= 1.6.0
- AWS CLI v2 configured with profile `personal`
- S3 bucket for state: `terformstatefile2026-077154311968-ap-south-1-an`
- DynamoDB table for locks: `terraform-state-lock`

### Secrets required in Secrets Manager (before first apply)

```
swat/prod/amazon-mq/admin          → { username, password, admin_username, admin_password }
```

### Apply order

```bash
# 1. Apply staging first to validate
cd environments/staging
terraform init
terraform apply

# 2. Apply production primary
cd environments/production/primary
terraform init
terraform apply

# 3. Capture outputs needed by DR
terraform output nlb_dns_name
terraform output cloudfront_domain_name

# 4. Update environments/production/dr/terraform.tfvars with the above outputs
# 5. Apply DR
cd environments/production/dr
terraform init
terraform apply

# 6. Feed DR outputs back to primary for Route 53 failover records
terraform output nlb_dns_name         # → set DR_NLB_DNS_NAME secret in GitHub
terraform output cloudfront_domain_name  # → set DR_CLOUDFRONT_DOMAIN_NAME secret
# Re-apply primary to update Route 53 DR health check
```

### Sensitive variables

Never put these in `.tfvars`. Set via environment variables before running:

```bash
export TF_VAR_cloudfront_origin_verify_secret="<random-string>"
```

Or set as GitHub Actions secrets:

| Secret | Used by |
|---|---|
| `CLOUDFRONT_ORIGIN_VERIFY_SECRET` | All environments |
| `ROUTE53_ZONE_ID` | Staging, DR |
| `DR_NLB_DNS_NAME` | Production primary |
| `DR_CLOUDFRONT_DOMAIN_NAME` | Production primary |
| `EKS_CLUSTER_ROLE_ARN` | Production DR |
| `EKS_NODE_GROUP_ROLE_ARN` | Production DR |
| `DEVOPS_EC2_INSTANCE_PROFILE_NAME` | Production DR |
| `S3_REPLICATION_ROLE_ARN` | Production DR |
| `AWS_ROLE_ARN_PROD` | Production GitHub Actions role |
| `AWS_ROLE_ARN_STAGING` | Staging GitHub Actions role |

---

## CI/CD

- **Plan workflow** — triggers on PR; plans all changed environments; comments plan output on the PR
- **Apply workflow** — triggers on merge to `main`; staging applies automatically; production requires manual approval via GitHub Environment protection rules
- **Auth method** — GitHub OIDC (`aws-actions/configure-aws-credentials`); no `AWS_ACCESS_KEY_ID` stored anywhere

---

## Security posture

| Control | Implementation |
|---|---|
| No secrets in code | Secrets Manager / SSM Parameter Store + `TF_VAR_*` env vars |
| `sensitive = true` | On all outputs containing credentials |
| EBS encrypted | KMS customer-managed key on all volumes |
| RDS encrypted | KMS on Aurora + `deletion_protection = true` |
| S3 hardened | Versioning + SSE-KMS + all 4 block-public-access controls |
| SG least-privilege | Only NLB accepts 0.0.0.0/0; all others use SG references |
| IMDSv2 required | `http_tokens = "required"` on all EC2 launch templates |
| VPC Endpoints | 13 interface + 2 gateway — no AWS API traffic over internet |
| No SSH keys | DevOps EC2 accessed via SSM Session Manager only |
| TLS 1.3 | ALB uses `ELBSecurityPolicy-TLS13-1-2-2021-06` |
| WAF | CRS + SQLi + known-bad-inputs + IP rate limit on CloudFront |
| OIDC CI/CD | GitHub Actions assumes IAM role via OIDC; no long-lived keys |

---

## Author

**Akash Yadav** — DevOps & Cloud Infrastructure Engineer
