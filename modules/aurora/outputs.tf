output "global_cluster_id" {
  description = "ID of the Aurora Global Cluster"
  value       = aws_rds_global_cluster.main.id
}

output "primary_cluster_id" {
  description = "Cluster identifier of the primary Aurora cluster"
  value       = aws_rds_cluster.primary.cluster_identifier
}

output "primary_cluster_endpoint" {
  description = "Writer endpoint of the primary Aurora cluster"
  value       = aws_rds_cluster.primary.endpoint
}

output "primary_cluster_reader_endpoint" {
  description = "Reader endpoint of the primary Aurora cluster"
  value       = aws_rds_cluster.primary.reader_endpoint
}

output "primary_cluster_port" {
  description = "Port the primary Aurora cluster listens on"
  value       = aws_rds_cluster.primary.port
}

output "dr_cluster_id" {
  description = "Cluster identifier of the DR Aurora cluster"
  value       = aws_rds_cluster.dr.cluster_identifier
}

output "dr_cluster_endpoint" {
  description = "Endpoint of the DR Aurora cluster (read-only until failover)"
  value       = aws_rds_cluster.dr.endpoint
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the master credentials (managed by RDS)"
  value       = aws_rds_cluster.primary.master_user_secret[0].secret_arn
  sensitive   = true
}

output "rds_monitoring_role_arn" {
  description = "ARN of the Enhanced Monitoring IAM role — pass to devops or backup modules if needed"
  value       = aws_iam_role.rds_monitoring.arn
}
