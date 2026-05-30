terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------
# Hosted Zone (use existing — not created here to avoid accidental deletion)
# -----------------------------------------------------------------------
data "aws_route53_zone" "main" {
  name         = var.hosted_zone_name
  private_zone = false
}

# -----------------------------------------------------------------------
# Health Checks
# -----------------------------------------------------------------------
resource "aws_route53_health_check" "primary" {
  fqdn              = var.primary_nlb_dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-health-check-primary"
  })
}

resource "aws_route53_health_check" "dr" {
  fqdn              = var.dr_nlb_dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-health-check-dr"
  })
}

# -----------------------------------------------------------------------
# A Record — CloudFront (PRIMARY)
# Failover routing: PRIMARY → CloudFront → NLB → ALB → EKS
# -----------------------------------------------------------------------
resource "aws_route53_record" "primary" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "${var.project}-${var.environment}-primary"
  health_check_id = aws_route53_health_check.primary.id

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = true
  }
}

# -----------------------------------------------------------------------
# A Record — DR CloudFront/NLB (SECONDARY)
# Only receives traffic when primary health check fails
# -----------------------------------------------------------------------
resource "aws_route53_record" "dr" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier  = "${var.project}-${var.environment}-dr"
  health_check_id = aws_route53_health_check.dr.id

  alias {
    name                   = var.dr_cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = true
  }
}

# -----------------------------------------------------------------------
# AAAA (IPv6) Records
# -----------------------------------------------------------------------
resource "aws_route53_record" "primary_aaaa" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "AAAA"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "${var.project}-${var.environment}-primary-aaaa"
  health_check_id = aws_route53_health_check.primary.id

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "dr_aaaa" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "AAAA"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier  = "${var.project}-${var.environment}-dr-aaaa"
  health_check_id = aws_route53_health_check.dr.id

  alias {
    name                   = var.dr_cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = true
  }
}
