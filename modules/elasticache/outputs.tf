output "primary_endpoint_address" {
  description = "Primary endpoint address for Redis writes"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint address for Redis reads"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "replication_group_id" {
  description = "Replication group ID"
  value       = aws_elasticache_replication_group.main.replication_group_id
}

output "port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.main.port
}
