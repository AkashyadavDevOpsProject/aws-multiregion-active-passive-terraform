output "file_system_id" {
  description = "EFS file system ID — used in Kubernetes StorageClass for EFS CSI driver"
  value       = aws_efs_file_system.main.id
}

output "file_system_arn" {
  description = "EFS file system ARN"
  value       = aws_efs_file_system.main.arn
}

output "dns_name" {
  description = "EFS DNS name for direct NFS mounting"
  value       = aws_efs_file_system.main.dns_name
}

output "access_point_ids" {
  description = "Map of access point name => ID"
  value       = { for k, ap in aws_efs_access_point.main : k => ap.id }
}

output "mount_target_ids" {
  description = "List of EFS mount target IDs"
  value       = [for mt in aws_efs_mount_target.main : mt.id]
}
