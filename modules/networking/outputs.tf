output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Map of AZ => subnet ID for public subnets"
  value       = { for az, s in aws_subnet.public : az => s.id }
}

output "public_subnet_ids_list" {
  description = "List of public subnet IDs (order matches availability_zones variable)"
  value       = [for az in var.availability_zones : aws_subnet.public[az].id]
}

output "private_app_subnet_ids" {
  description = "Map of AZ => subnet ID for private app subnets"
  value       = { for az, s in aws_subnet.private_app : az => s.id }
}

output "private_app_subnet_ids_list" {
  description = "List of private app subnet IDs (order matches availability_zones variable)"
  value       = [for az in var.availability_zones : aws_subnet.private_app[az].id]
}

output "private_db_subnet_ids" {
  description = "Map of AZ => subnet ID for private DB subnets"
  value       = { for az, s in aws_subnet.private_db : az => s.id }
}

output "private_db_subnet_ids_list" {
  description = "List of private DB subnet IDs (order matches availability_zones variable)"
  value       = [for az in var.availability_zones : aws_subnet.private_db[az].id]
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "Map of AZ => NAT Gateway ID"
  value       = { for az, ngw in aws_nat_gateway.main : az => ngw.id }
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_app_route_table_ids" {
  description = "Map of AZ => private app route table ID"
  value       = { for az, rt in aws_route_table.private_app : az => rt.id }
}

output "private_db_route_table_id" {
  description = "ID of the shared private DB route table"
  value       = aws_route_table.private_db.id
}
