# Module: route53

Configures Route 53 active-passive failover routing between primary (ap-south-1) and DR (ap-south-2) using health checks on both CloudFront distributions.

## Failover behavior

- **Normal:** All traffic → PRIMARY record → primary CloudFront → NLB → ALB → EKS
- **Failover:** PRIMARY health check fails → DNS TTL expires → traffic shifts to SECONDARY record → DR CloudFront

Health checks poll the NLB endpoint on port 443 every 30 seconds. Failover triggers after 3 consecutive failures (~90 seconds).

**Note:** The hosted zone is looked up via `data` source, not created. This prevents accidental zone deletion via `terraform destroy`.
