output "alarms_sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms — pass to backup and other modules"
  value       = aws_sns_topic.alarms.arn
}

output "application_log_group_name" {
  description = "CloudWatch log group name for application logs"
  value       = aws_cloudwatch_log_group.application.name
}

output "xray_group_arn" {
  description = "ARN of the X-Ray group"
  value       = aws_xray_group.main.arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
