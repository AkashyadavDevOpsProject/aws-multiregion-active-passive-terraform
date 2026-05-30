# Architectural Decision Records

Design decisions made during the implementation of `terraform-swat-aws-dr`, with rationale and trade-offs documented.

---

## ADR-001: Active-passive DR over active-active

**Decision:** ap-south-2 runs reduced-capacity warm standby, not a mirror of production.

**Rationale:** Active-active requires synchronous write replication across regions, which Aurora Global DB does not support in write mode. For a financial application where data consistency is paramount, active-passive with async replication is the correct trade-off: you accept higher RTO (minutes, not seconds) in exchange for RPO near-zero and zero risk of split-brain.

**Trade-off:** Failover requires Aurora Global DB promotion (manual AWS CLI command). Automated failover is not enabled — this is intentional for financial data.

---

## ADR-002: All security groups in a single module

**Decision:** `security-groups` module creates every SG in the architecture.

**Rationale:** Terraform cannot create two resources that each reference the other in the same plan. If `eks_nodes` SG references `alb` SG and `alb` SG references `eks_nodes` SG, Terraform deadlocks. Centralising SGs in one module with a `depends_on`-free creation order eliminates this problem entirely.

**Trade-off:** The SG module has no semantic grouping by service. Compensated with clear resource names and inline `description` fields.

---

## ADR-003: IRSA roles created in the EKS module, not IAM module

**Decision:** IAM module creates cluster/node/EC2 roles. IRSA roles are created inside the EKS module.

**Rationale:** IRSA roles require the cluster OIDC provider URL as a condition key. The OIDC provider URL only exists after the EKS cluster is provisioned. Creating IRSA roles in a separate IAM module would require passing the cluster URL as an input, creating a dependency cycle (IAM → EKS → IAM). Placing IRSA roles inside the EKS module after the OIDC provider resource breaks the cycle cleanly.

**Trade-off:** EKS module is larger than typical modules. Acceptable given the tight coupling between IRSA and the cluster OIDC provider.

---

## ADR-004: Launch Template instead of Launch Configuration for DevOps EC2

**Decision:** DevOps EC2 uses `aws_launch_template` not `aws_launch_configuration`.

**Rationale:** AWS deprecated Launch Configurations in late 2023. Launch Templates support IMDSv2 enforcement, gp3 EBS volumes, instance refresh on ASG, and are required for new EC2 Auto Scaling Group features. Using a deprecated resource in a portfolio project would signal unfamiliarity with current AWS practices.

**Trade-off:** Launch Templates have a more complex structure than Launch Configurations. The additional complexity is handled by the `devops-ec2` module's abstraction.

---

## ADR-005: NLB-to-ALB chaining for public ingress

**Decision:** Traffic enters a public NLB, which forwards to a private ALB via `target_type = "alb"`.

**Rationale:** CloudFront cannot target an ALB directly as an origin using a VPC-internal endpoint — it needs a publicly resolvable DNS name with static IPs. The NLB provides static IPs (for IP allow-listing and CloudFront) while the ALB handles L7 routing (path-based rules, host-based routing, HTTPS redirect). NLB-to-ALB chaining (AWS feature released 2023) replaces the older pattern of putting the ALB in public subnets.

**Trade-off:** Adds one hop. The latency cost is sub-millisecond within a VPC. Security benefit (ALB never directly internet-facing) outweighs it.

---

## ADR-006: `manage_master_user_password = true` on Aurora

**Decision:** Aurora master credentials are RDS-managed in Secrets Manager, not set via Terraform variables.

**Rationale:** Terraform state files can be read by anyone with S3 access to the state bucket. If the master password were a Terraform variable, it would appear in plain text in `terraform.tfstate`. `manage_master_user_password = true` delegates credential creation and rotation entirely to RDS — the password never touches Terraform state, CI/CD logs, or `.tfvars` files.

**Trade-off:** Terraform cannot verify the password during plan. The Secrets Manager secret ARN is an output and must be used by application config management.

---

## ADR-007: S3 buckets named with account ID and region suffix

**Decision:** Bucket names follow the pattern `<project>-<env>-<suffix>-<account_id>-<region>`.

**Rationale:** S3 bucket names are globally unique. Including the account ID and region prevents name collisions when the same Terraform code is applied across multiple accounts or when another team uses the same project prefix. It also makes bucket ownership immediately identifiable from the name alone.

**Trade-off:** Longer bucket names. Not a functional concern.

---

## ADR-008: Route 53 hosted zone looked up via `data` source

**Decision:** The `route53` module uses `data "aws_route53_zone"` instead of `resource "aws_route53_zone"`.

**Rationale:** The hosted zone for a production domain is a singleton that predates this Terraform project. Creating it as a resource means `terraform destroy` would delete the zone and all DNS records in it, causing a complete DNS outage. Using a `data` source makes the module consume the zone without owning its lifecycle.

**Trade-off:** The zone must be created manually before the first `terraform apply`. This is documented in the README.

---

## ADR-009: production/primary and production/dr as separate Terraform root modules

**Decision:** DR environment is a separate directory with its own state file, not a workspace or a `region` variable inside the same root module.

**Rationale:**
1. DR failover must be executable as a standalone `terraform apply` without touching primary state
2. DR uses different instance sizes (warm standby cost reduction) — a single `.tfvars` per environment expresses this clearly
3. If primary and DR shared state, a corrupted primary apply could block DR operations during an incident
4. Separate state files mean the Aurora Global Cluster secondary was provisioned from the primary's root module, which holds the global cluster resource — this is the only cross-state dependency and is intentional

**Trade-off:** Some variables (EKS cluster role ARN, node group role ARN) must be passed from primary outputs to DR `.tfvars` after first apply. Documented in README apply order.

---

## ADR-010: VPC Endpoints for all AWS API calls

**Decision:** 13 interface endpoints + S3/DynamoDB gateway endpoints provisioned in every environment.

**Rationale:** EKS pods pulling from ECR, sending to CloudWatch, and exchanging STS tokens for IRSA must traverse the NAT Gateway without endpoints — generating per-GB NAT charges and creating an internet egress path for internal AWS API traffic. VPC Endpoints eliminate both the cost (gateway endpoints are free; interface endpoints cost ~$0.01/hour) and the security exposure. For a financial application, zero AWS API traffic over the internet is a compliance expectation.

**Trade-off:** Interface endpoints bill per endpoint-hour and per-GB processed. 13 interface endpoints in production ≈ $115/month before data transfer. Justified by security posture and NAT savings at scale.

---

## ADR-011: GitHub OIDC instead of IAM user keys for CI/CD

**Decision:** GitHub Actions assumes an IAM role via OIDC token exchange (`aws-actions/configure-aws-credentials`). No `AWS_ACCESS_KEY_ID` is stored in GitHub Secrets.

**Rationale:** Long-lived IAM access keys are a persistent credential that can be leaked through log exposure, secret scanning misses, or repository forks. OIDC tokens are short-lived (15 minutes), scoped to a specific repository and branch, and require no rotation. This eliminates the #1 cause of AWS account compromise from CI/CD pipelines.

**Trade-off:** Initial setup requires creating the OIDC provider and trust policy (done in the `iam` module). The GitHub Actions workflow is slightly more complex. Both are one-time costs.

---

## ADR-012: Aurora replication lag alarm at 30 seconds

**Decision:** `AuroraGlobalDBReplicationLag` CloudWatch alarm threshold is 30,000 ms.

**Rationale:** Aurora Global DB guarantees < 1 second replication lag under normal conditions. A 30-second lag means the DR cluster is 30 seconds behind primary — if a failover occurs at that moment, up to 30 seconds of committed transactions would be lost (RPO breach). For a financial application, this is the earliest warning that DR RPO is at risk. The alarm fires after 2 consecutive periods (2 minutes of sustained lag) to avoid false positives from transient network spikes.

**Trade-off:** 30 seconds is conservative. Teams may tune this threshold based on their specific RPO SLA.
