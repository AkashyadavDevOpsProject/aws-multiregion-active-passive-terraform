output "broker_id" {
  description = "Amazon MQ broker ID"
  value       = aws_mq_broker.main.id
}

output "broker_arn" {
  description = "Amazon MQ broker ARN"
  value       = aws_mq_broker.main.arn
}

output "amqp_ssl_endpoints" {
  description = "AMQP+SSL endpoints for application connection"
  value       = [for instance in aws_mq_broker.main.instances : instance.endpoints[0]]
}

output "stomp_ssl_endpoints" {
  description = "STOMP+SSL endpoints"
  value       = [for instance in aws_mq_broker.main.instances : instance.endpoints[1]]
}

output "console_url" {
  description = "ActiveMQ web console URL (accessible from DevOps EC2 via SSM tunnel)"
  value       = aws_mq_broker.main.instances[0].console_url
}
