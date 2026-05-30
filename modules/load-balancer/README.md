# Module: load-balancer

Provisions the full ingress chain: Public NLB → Private ALB → EKS pods.

## Traffic flow

```
Internet → Public NLB (TCP 443) → Target Type: alb → Private ALB → Path rules → EKS pod IPs
```

The NLB uses `target_type = "alb"` (NLB-to-ALB chaining), allowing the ALB to handle L7 routing while the NLB provides static IPs for CloudFront origin.

## ALB SSL policy

Uses `ELBSecurityPolicy-TLS13-1-2-2021-06` — TLS 1.3 preferred, minimum TLS 1.2, no deprecated ciphers.

## ALB Listener Rules

Pass `listener_rules` map to add path-based routing:

```hcl
listener_rules = {
  payments-api = {
    priority         = 100
    target_group_key = "payments"
    path_patterns    = ["/api/payments/*"]
  }
}
```
