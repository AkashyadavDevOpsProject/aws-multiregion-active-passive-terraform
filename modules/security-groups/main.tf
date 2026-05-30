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
# Public NLB Security Group
# Accepts HTTPS from anywhere (CloudFront forwards to NLB)
# -----------------------------------------------------------------------
resource "aws_security_group" "nlb_public" {
  name        = "${var.project}-${var.environment}-sg-nlb-public"
  description = "Public NLB — HTTPS ingress from internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP redirect from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-sg-nlb-public"
  })
}

# -----------------------------------------------------------------------
# Private ALB Security Group
# Accepts traffic from NLB SG only
# -----------------------------------------------------------------------
resource "aws_security_group" "alb_private" {
  name        = "${var.project}-${var.environment}-sg-alb-private"
  description = "Private ALB — ingress from NLB only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS from NLB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb_public.id]
  }

  ingress {
    description     = "HTTP from NLB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb_public.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-sg-alb-private"
  })
}

# -----------------------------------------------------------------------
# EKS Cluster Security Group (control plane)
# -----------------------------------------------------------------------
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project}-${var.environment}-sg-eks-cluster"
  description = "EKS control plane — managed by AWS, additional rules only"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-sg-eks-cluster"
    "kubernetes.io/cluster/${var.project}-${var.environment}-eks-cluster" = "owned"
  })
}

# -----------------------------------------------------------------------
# EKS Node Group Security Group
# -----------------------------------------------------------------------
resource "aws_security_group" "eks_nodes" {
  name        = "${var.project}-${var.environment}-sg-eks-nodes"
  description = "EKS worker nodes — inter-node + ALB + control plane communication"
  vpc_id      = var.vpc_id

  ingress {
    description = "Node-to-node all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description     = "Control plane to nodes (kubelet API)"
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  ingress {
    description     = "App traffic from private ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_private.id]
  }

  ingress {
    description     = "App traffic from private ALB (HTTPS)"
    from_port       = 8443
    to_port         = 8443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_private.id]
  }

  ingress {
    description     = "NodePort range from ALB"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_private.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-sg-eks-nodes"
    "kubernetes.io/cluster/${var.project}-${var.environment}-eks-cluster" = "owned"
  })
}

# Allow control plane to receive responses from nodes
resource "aws_security_group_rule" "cluster_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "Nodes to control plane (API server)"
}

# -----------------------------------------------------------------------
# DevOps EC2 Security Group
# No SSH — access only via SSM Session Manager
# -----------------------------------------------------------------------
resource "aws_security_group" "devops_ec2" {
  name        = "${var.project}-${var.environment}-sg-devops-ec2"
  description = "DevOps EC2 — no inbound SSH; access via SSM only"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound (SSM, ECR, EKS API)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-sg-devops-ec2"
  })
}

# -----------------------------------------------------------------------
# Aurora Security Group
# -----------------------------------------------------------------------
resource "aws_security_group" "aurora" {
  name        = "${var.project}-${var.environment}-sg-aurora"
  description = "Aurora PostgreSQL — ingress from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  ingress {
    description     = "PostgreSQL from DevOps EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.devops_ec2.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-sg-aurora"
  })
}

# -----------------------------------------------------------------------
# ElastiCache Redis Security Group
# -----------------------------------------------------------------------
resource "aws_security_group" "elasticache" {
  name        = "${var.project}-${var.environment}-sg-elasticache"
  description = "ElastiCache Redis — ingress from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from EKS nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-sg-elasticache"
  })
}

# -----------------------------------------------------------------------
# Amazon MQ Security Group
# -----------------------------------------------------------------------
resource "aws_security_group" "amazon_mq" {
  name        = "${var.project}-${var.environment}-sg-amazon-mq"
  description = "Amazon MQ broker — ingress from EKS nodes on AMQP/STOMP/MQTT ports"
  vpc_id      = var.vpc_id

  ingress {
    description     = "AMQP from EKS nodes"
    from_port       = 5671
    to_port         = 5671
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  ingress {
    description     = "OpenWire (ActiveMQ) from EKS nodes"
    from_port       = 61617
    to_port         = 61617
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  ingress {
    description     = "MQ web console from DevOps EC2"
    from_port       = 8162
    to_port         = 8162
    protocol        = "tcp"
    security_groups = [aws_security_group.devops_ec2.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-sg-amazon-mq"
  })
}

# -----------------------------------------------------------------------
# EFS Security Group
# -----------------------------------------------------------------------
resource "aws_security_group" "efs" {
  name        = "${var.project}-${var.environment}-sg-efs"
  description = "EFS mount targets — NFS ingress from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from EKS nodes"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-sg-efs"
  })
}

# -----------------------------------------------------------------------
# VPC Endpoints Security Group
# -----------------------------------------------------------------------
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project}-${var.environment}-sg-vpc-endpoints"
  description = "Interface VPC Endpoints — HTTPS ingress from within VPC only"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-sg-vpc-endpoints"
  })
}
