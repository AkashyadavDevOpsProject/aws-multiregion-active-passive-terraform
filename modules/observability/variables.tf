variable "project" { type = string }
variable "environment" { type = string }
variable "region" { type = string }

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 90
}

variable "kms_key_arn" {
  description = "KMS key ARN for SNS topic encryption"
  type        = string
}

variable "alarm_email_endpoints" {
  description = "Email addresses to subscribe to the alarms SNS topic"
  type        = list(string)
  default     = []
}

variable "alarm_sns_topic_arns" {
  description = "Additional SNS topic ARNs to send alarm actions to (in addition to the one created here)"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
