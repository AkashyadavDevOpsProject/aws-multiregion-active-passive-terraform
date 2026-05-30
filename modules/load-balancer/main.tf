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
# Public NLB
# -----------------------------------------------------------------------
resource "aws_lb" "nlb_public" {
  name               = "${var.project}-${var.environment}-nlb-public"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids
  security_groups    = [var.nlb_sg_id]

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = "${var.project}-${var.environment}-nlb-public"
    enabled = var.enable_access_logs
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-nlb-public"
  })
}

# NLB Target Group → ALB (NLB-to-ALB chaining)
resource "aws_lb_target_group" "nlb_to_alb" {
  name        = "${var.project}-${var.environment}-nlb-tg-alb"
  port        = 443
  protocol    = "TCP"
  target_type = "alb"
  vpc_id      = var.vpc_id

  health_check {
    protocol            = "HTTPS"
    path                = var.health_check_path
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-nlb-tg-alb"
  })
}

resource "aws_lb_target_group_attachment" "nlb_to_alb" {
  target_group_arn = aws_lb_target_group.nlb_to_alb.arn
  target_id        = aws_lb.alb_private.arn
  port             = 443
}

# NLB Listener — HTTPS/TCP 443
resource "aws_lb_listener" "nlb_https" {
  load_balancer_arn = aws_lb.nlb_public.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_to_alb.arn
  }

  tags = var.tags
}

# NLB Listener — HTTP/TCP 80 → redirect via ALB
resource "aws_lb_listener" "nlb_http" {
  load_balancer_arn = aws_lb.nlb_public.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_to_alb.arn
  }

  tags = var.tags
}

# -----------------------------------------------------------------------
# Private ALB
# -----------------------------------------------------------------------
resource "aws_lb" "alb_private" {
  name               = "${var.project}-${var.environment}-alb-private"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.private_app_subnet_ids
  security_groups    = [var.alb_sg_id]

  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true

  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = "${var.project}-${var.environment}-alb-private"
    enabled = var.enable_access_logs
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-alb-private"
  })
}

# ALB Target Group → EKS pods
resource "aws_lb_target_group" "alb_to_eks" {
  for_each = var.target_groups

  name        = "${var.project}-${var.environment}-tg-${each.key}"
  port        = each.value.port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = each.value.health_check_path
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-tg-${each.key}"
  })
}

# ALB Listener — HTTPS 443
resource "aws_lb_listener" "alb_https" {
  load_balancer_arn = aws_lb.alb_private.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = var.tags
}

# ALB Listener — HTTP 80 → redirect to HTTPS
resource "aws_lb_listener" "alb_http_redirect" {
  load_balancer_arn = aws_lb.alb_private.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = var.tags
}

# ALB Listener Rules
resource "aws_lb_listener_rule" "alb_routes" {
  for_each = var.listener_rules

  listener_arn = aws_lb_listener.alb_https.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_to_eks[each.value.target_group_key].arn
  }

  condition {
    path_pattern {
      values = each.value.path_patterns
    }
  }
}
