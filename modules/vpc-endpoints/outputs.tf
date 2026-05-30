output "interface_endpoint_ids" {
  description = "Map of endpoint key => VPC Endpoint ID for all interface endpoints"
  value       = { for k, ep in aws_vpc_endpoint.interface : k => ep.id }
}

output "s3_endpoint_id" {
  description = "ID of the S3 Gateway VPC Endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "dynamodb_endpoint_id" {
  description = "ID of the DynamoDB Gateway VPC Endpoint"
  value       = aws_vpc_endpoint.dynamodb.id
}
