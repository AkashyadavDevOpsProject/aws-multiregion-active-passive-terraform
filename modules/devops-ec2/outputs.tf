output "launch_template_id" {
  description = "ID of the DevOps EC2 launch template"
  value       = aws_launch_template.devops_ec2.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group managing the DevOps EC2"
  value       = aws_autoscaling_group.devops_ec2.name
}

output "ami_id_used" {
  description = "AMI ID used for the DevOps EC2 (resolved from data source if not explicitly set)"
  value       = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2023.id
}
