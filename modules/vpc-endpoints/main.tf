terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  # Interface endpoints — need ENIs in subnets + SG
  interface_endpoints = {
    ecr_api = {
      service_name = "com.amazonaws.${var.region}.ecr.api"
      description  = "ECR API — pull image manifests without internet"
    }
    ecr_dkr = {
      service_name = "com.amazonaws.${var.region}.ecr.dkr"
      description  = "ECR Docker — pull image layers without internet"
    }
    eks = {
      service_name = "com.amazonaws.${var.region}.eks"
      description  = "EKS API server private access"
    }
    sts = {
      service_name = "com.amazonaws.${var.region}.sts"
      description  = "STS — IRSA token exchange without internet"
    }
    ssm = {
      service_name = "com.amazonaws.${var.region}.ssm"
      description  = "SSM — Session Manager for DevOps EC2"
    }
    ssmmessages = {
      service_name = "com.amazonaws.${var.region}.ssmmessages"
      description  = "SSM Messages — Session Manager data channel"
    }
    ec2messages = {
      service_name = "com.amazonaws.${var.region}.ec2messages"
      description  = "EC2 Messages — SSM agent communication"
    }
    secretsmanager = {
      service_name = "com.amazonaws.${var.region}.secretsmanager"
      description  = "Secrets Manager — app secret retrieval without internet"
    }
    logs = {
      service_name = "com.amazonaws.${var.region}.logs"
      description  = "CloudWatch Logs — log shipping without internet"
    }
    monitoring = {
      service_name = "com.amazonaws.${var.region}.monitoring"
      description  = "CloudWatch Metrics — metrics push without internet"
    }
    xray = {
      service_name = "com.amazonaws.${var.region}.xray"
      description  = "X-Ray — trace shipping without internet"
    }
    elasticloadbalancing = {
      service_name = "com.amazonaws.${var.region}.elasticloadbalancing"
      description  = "ELB API — ALB/NLB controller operations"
    }
    autoscaling = {
      service_name = "com.amazonaws.${var.region}.autoscaling"
      description  = "Auto Scaling — cluster autoscaler operations"
    }
  }
}

# -----------------------------------------------------------------------
# Interface Endpoints
# -----------------------------------------------------------------------
resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = var.vpc_id
  service_name        = each.value.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_app_subnet_ids
  security_group_ids  = [var.vpc_endpoints_sg_id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-vpce-${each.key}"
    Description = each.value.description
  })
}

# -----------------------------------------------------------------------
# Gateway Endpoint — S3 (free, attached to route tables)
# -----------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(
    values(var.private_app_route_table_ids),
    [var.private_db_route_table_id]
  )

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-vpce-s3"
    Description = "S3 Gateway — S3 access without internet or NAT charges"
  })
}

# -----------------------------------------------------------------------
# Gateway Endpoint — DynamoDB (Terraform state lock table)
# -----------------------------------------------------------------------
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(
    values(var.private_app_route_table_ids),
    [var.private_db_route_table_id]
  )

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-vpce-dynamodb"
    Description = "DynamoDB Gateway — state lock table access without internet"
  })
}
