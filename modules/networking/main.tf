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
# VPC
# -----------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-vpc"
  })
}

# -----------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-igw"
  })
}

# -----------------------------------------------------------------------
# Public Subnets  (one per AZ) — NLB, NAT GW
# -----------------------------------------------------------------------
resource "aws_subnet" "public" {
  for_each = { for idx, az in var.availability_zones : az => {
    cidr = var.public_subnet_cidrs[idx]
    az   = az
  }}

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name                                              = "${var.project}-${var.environment}-public-${each.value.az}"
    "kubernetes.io/role/elb"                          = "1"
    "kubernetes.io/cluster/${var.project}-${var.environment}-eks-cluster" = "shared"
  })
}

# -----------------------------------------------------------------------
# Private App Subnets (one per AZ) — EKS node groups, ALB, DevOps EC2
# -----------------------------------------------------------------------
resource "aws_subnet" "private_app" {
  for_each = { for idx, az in var.availability_zones : az => {
    cidr = var.private_app_subnet_cidrs[idx]
    az   = az
  }}

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name                                              = "${var.project}-${var.environment}-private-app-${each.value.az}"
    "kubernetes.io/role/internal-elb"                 = "1"
    "kubernetes.io/cluster/${var.project}-${var.environment}-eks-cluster" = "shared"
  })
}

# -----------------------------------------------------------------------
# Private DB Subnets (one per AZ) — Aurora, ElastiCache, MQ, EFS
# -----------------------------------------------------------------------
resource "aws_subnet" "private_db" {
  for_each = { for idx, az in var.availability_zones : az => {
    cidr = var.private_db_subnet_cidrs[idx]
    az   = az
  }}

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-private-db-${each.value.az}"
  })
}

# -----------------------------------------------------------------------
# Elastic IPs for NAT Gateways (one per AZ for HA)
# -----------------------------------------------------------------------
resource "aws_eip" "nat" {
  for_each = toset(var.availability_zones)

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-nat-eip-${each.key}"
  })

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------
# NAT Gateways (one per AZ) — HA outbound for private subnets
# -----------------------------------------------------------------------
resource "aws_nat_gateway" "main" {
  for_each = toset(var.availability_zones)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------
# Route Tables — Public
# -----------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-rt-public"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------------------------
# Route Tables — Private App (one per AZ, routes via AZ-local NAT GW)
# -----------------------------------------------------------------------
resource "aws_route_table" "private_app" {
  for_each = toset(var.availability_zones)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[each.key].id
  }

  dynamic "route" {
    for_each = var.transit_gateway_id != null ? [1] : []
    content {
      cidr_block         = var.tgw_destination_cidr
      transit_gateway_id = var.transit_gateway_id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-rt-private-app-${each.key}"
  })
}

resource "aws_route_table_association" "private_app" {
  for_each = aws_subnet.private_app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app[each.key].id
}

# -----------------------------------------------------------------------
# Route Tables — Private DB (shared, no internet, TGW route optional)
# -----------------------------------------------------------------------
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.transit_gateway_id != null ? [1] : []
    content {
      cidr_block         = var.tgw_destination_cidr
      transit_gateway_id = var.transit_gateway_id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-rt-private-db"
  })
}

resource "aws_route_table_association" "private_db" {
  for_each = aws_subnet.private_db

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db.id
}

# -----------------------------------------------------------------------
# VPC Flow Logs — CloudWatch
# -----------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/${var.project}-${var.environment}-flow-logs"
  retention_in_days = var.flow_logs_retention_days

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-vpc-flow-logs"
  })
}

resource "aws_iam_role" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.project}-${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.project}-${var.environment}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.vpc_flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-flow-log"
  })
}
