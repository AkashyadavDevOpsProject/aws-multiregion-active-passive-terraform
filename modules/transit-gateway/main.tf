terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.dr]
    }
  }
}

# -----------------------------------------------------------------------
# Transit Gateway (created in primary region)
# -----------------------------------------------------------------------
resource "aws_ec2_transit_gateway" "main" {
  description                     = "${var.project}-${var.environment} TGW — connects primary (${var.primary_region}) to DR (${var.dr_region})"
  amazon_side_asn                 = var.amazon_side_asn
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-tgw"
  })
}

# -----------------------------------------------------------------------
# TGW VPC Attachment — Primary VPC (ap-south-1)
# -----------------------------------------------------------------------
resource "aws_ec2_transit_gateway_vpc_attachment" "primary" {
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  vpc_id                                          = var.primary_vpc_id
  subnet_ids                                      = var.primary_private_app_subnet_ids
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  dns_support                                     = "enable"

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-tgw-attach-primary"
  })
}

# -----------------------------------------------------------------------
# TGW VPC Attachment — DR VPC (ap-south-2)
# -----------------------------------------------------------------------
resource "aws_ec2_transit_gateway_vpc_attachment" "dr" {
  provider = aws.dr

  transit_gateway_id                              = aws_ec2_transit_gateway_peering_attachment.primary_to_dr.peer_transit_gateway_id
  vpc_id                                          = var.dr_vpc_id
  subnet_ids                                      = var.dr_private_app_subnet_ids
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  dns_support                                     = "enable"

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-tgw-attach-dr"
  })
}

# -----------------------------------------------------------------------
# TGW in DR Region (ap-south-2)
# -----------------------------------------------------------------------
resource "aws_ec2_transit_gateway" "dr" {
  provider = aws.dr

  description                     = "${var.project}-${var.environment} TGW DR — ${var.dr_region}"
  amazon_side_asn                 = var.dr_amazon_side_asn
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-tgw-dr"
  })
}

# -----------------------------------------------------------------------
# TGW Peering Attachment (primary → DR)
# -----------------------------------------------------------------------
resource "aws_ec2_transit_gateway_peering_attachment" "primary_to_dr" {
  transit_gateway_id      = aws_ec2_transit_gateway.main.id
  peer_transit_gateway_id = aws_ec2_transit_gateway.dr.id
  peer_region             = var.dr_region

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-tgw-peering"
  })
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "dr_accepts" {
  provider = aws.dr

  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.primary_to_dr.id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-tgw-peering-accepter"
  })
}

# -----------------------------------------------------------------------
# TGW Route Tables
# -----------------------------------------------------------------------
resource "aws_ec2_transit_gateway_route_table" "primary" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-tgw-rt-primary"
  })
}

resource "aws_ec2_transit_gateway_route_table" "dr" {
  provider = aws.dr

  transit_gateway_id = aws_ec2_transit_gateway.dr.id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-tgw-rt-dr"
  })
}

# -----------------------------------------------------------------------
# TGW Route Table Associations
# -----------------------------------------------------------------------
resource "aws_ec2_transit_gateway_route_table_association" "primary_vpc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.primary.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.primary.id
}

resource "aws_ec2_transit_gateway_route_table_association" "dr_vpc" {
  provider = aws.dr

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dr.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dr.id
}

# -----------------------------------------------------------------------
# TGW Static Routes
# -----------------------------------------------------------------------
resource "aws_ec2_transit_gateway_route" "primary_to_dr" {
  destination_cidr_block         = var.dr_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.primary_to_dr.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.primary.id
}

resource "aws_ec2_transit_gateway_route" "dr_to_primary" {
  provider = aws.dr

  destination_cidr_block         = var.primary_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.primary_to_dr.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dr.id
}
