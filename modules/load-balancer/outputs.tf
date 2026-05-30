output "nlb_arn" {
  description = "ARN of the public NLB"
  value       = aws_lb.nlb_public.arn
}

output "nlb_dns_name" {
  description = "DNS name of the public NLB — used as CloudFront origin"
  value       = aws_lb.nlb_public.dns_name
}

output "nlb_zone_id" {
  description = "Route 53 zone ID of the NLB — used for alias records"
  value       = aws_lb.nlb_public.zone_id
}

output "alb_arn" {
  description = "ARN of the private ALB"
  value       = aws_lb.alb_private.arn
}

output "alb_dns_name" {
  description = "DNS name of the private ALB"
  value       = aws_lb.alb_private.dns_name
}

output "alb_https_listener_arn" {
  description = "ARN of the ALB HTTPS listener — used to add rules from other modules"
  value       = aws_lb_listener.alb_https.arn
}

output "target_group_arns" {
  description = "Map of target group key => ARN"
  value       = { for k, tg in aws_lb_target_group.alb_to_eks : k => tg.arn }
}
