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
# Latest Amazon Linux 2023 AMI
# -----------------------------------------------------------------------
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------------------------------
# Launch Template (replaces deprecated Launch Configuration)
# -----------------------------------------------------------------------
resource "aws_launch_template" "devops_ec2" {
  name        = "${var.project}-${var.environment}-devops-ec2-lt"
  description = "Launch template for DevOps EC2 — kubectl, helm, AWS CLI, SSM access"

  image_id      = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [var.security_group_id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size_gb
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.kms_key_arn
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh.tpl", {
    cluster_name = var.eks_cluster_name
    region       = var.region
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.project}-${var.environment}-devops-ec2"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name = "${var.project}-${var.environment}-devops-ec2-volume"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-devops-ec2-lt"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------
# Auto Scaling Group (single instance, ensures replacement on failure)
# -----------------------------------------------------------------------
resource "aws_autoscaling_group" "devops_ec2" {
  name                = "${var.project}-${var.environment}-devops-ec2-asg"
  vpc_zone_identifier = [var.subnet_id]
  desired_capacity    = 1
  min_size            = 0
  max_size            = 1

  launch_template {
    id      = aws_launch_template.devops_ec2.id
    version = aws_launch_template.devops_ec2.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
    }
  }

  dynamic "tag" {
    for_each = merge(var.tags, {
      Name = "${var.project}-${var.environment}-devops-ec2"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
