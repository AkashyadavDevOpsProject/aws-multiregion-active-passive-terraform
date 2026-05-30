# Module: cloudfront

Provisions a CloudFront distribution backed by the public NLB, with a WAF WebACL in us-east-1. All managed AWS WAF rule groups are included: CRS, SQLi, known-bad-inputs, and IP rate limiting.

## Provider requirements

Requires `aws.us_east_1` provider alias (WAF must be in us-east-1 for CloudFront).

## Origin verify header

`origin_verify_secret` is set as a custom header `X-Origin-Verify` on all requests to the NLB origin. To block direct NLB access, add an ALB listener rule that returns 403 if this header is absent — preventing CloudFront bypass attacks.

## WAF rules included

| Rule set | Priority |
|---|---|
| AWSManagedRulesCommonRuleSet | 10 |
| AWSManagedRulesKnownBadInputsRuleSet | 20 |
| AWSManagedRulesSQLiRuleSet | 30 |
| IP Rate Limit (2000 req/5min) | 40 |

WAF logs → CloudWatch Logs (`aws-waf-logs-*`, retained 90 days).
