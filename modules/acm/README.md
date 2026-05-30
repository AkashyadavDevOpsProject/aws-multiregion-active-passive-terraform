# Module: acm

Provisions two ACM certificates for the same domain:

| Certificate | Region | Purpose |
|---|---|---|
| `primary` | ap-south-1 | ALB / NLB HTTPS listeners |
| `cloudfront` | us-east-1 | CloudFront distribution (CloudFront requires certs in us-east-1) |

Both certificates use **DNS validation** via Route 53 CNAME records. Validation records are created inside the module — pass the `route53_zone_id` for the hosted zone that controls your domain.

## Provider requirements

This module requires **two provider configurations** from the calling root module:

```hcl
provider "aws" {
  profile = "personal"
  region  = "ap-south-1"
}

provider "aws" {
  alias   = "us_east_1"
  profile = "personal"
  region  = "us-east-1"
}
```

Pass both providers when calling the module:

```hcl
module "acm" {
  source = "../../modules/acm"

  providers = {
    aws          = aws
    aws.us_east_1 = aws.us_east_1
  }

  project                   = var.project
  environment               = var.environment
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  route53_zone_id           = module.route53.zone_id
  tags                      = local.common_tags
}
```

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `project` | string | yes | Project name prefix |
| `environment` | string | yes | Environment name |
| `domain_name` | string | yes | Primary domain (e.g., `app.example.com`) |
| `subject_alternative_names` | list(string) | no | SANs (e.g., `["*.example.com"]`) |
| `route53_zone_id` | string | yes | Hosted zone ID for DNS validation records |
| `tags` | map(string) | no | Additional tags merged on all resources |

## Outputs

| Name | Description |
|---|---|
| `primary_certificate_arn` | Used by ALB/NLB HTTPS listeners |
| `cloudfront_certificate_arn` | Used by the CloudFront distribution |
| `primary_domain_validation_options` | DNS validation details for debugging |
