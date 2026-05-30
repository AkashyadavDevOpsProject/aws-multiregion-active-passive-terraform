output "vault_arn" {
  description = "ARN of the AWS Backup vault"
  value       = aws_backup_vault.main.arn
}

output "vault_name" {
  description = "Name of the AWS Backup vault"
  value       = aws_backup_vault.main.name
}

output "plan_id" {
  description = "ID of the AWS Backup plan"
  value       = aws_backup_plan.main.id
}

output "alarm_sns_topic_arn" {
  description = "ARN of the backup failure alarm SNS topic"
  value       = aws_cloudwatch_metric_alarm.backup_failures.alarm_actions
}
