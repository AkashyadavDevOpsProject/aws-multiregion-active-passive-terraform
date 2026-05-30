output "zone_id" {
  description = "Route 53 hosted zone ID — used by acm module for DNS validation records"
  value       = data.aws_route53_zone.main.zone_id
}

output "primary_health_check_id" {
  description = "ID of the primary region Route 53 health check"
  value       = aws_route53_health_check.primary.id
}

output "dr_health_check_id" {
  description = "ID of the DR region Route 53 health check"
  value       = aws_route53_health_check.dr.id
}
