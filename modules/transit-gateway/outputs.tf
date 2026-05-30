output "primary_tgw_id" {
  description = "ID of the Transit Gateway in the primary region — passed to networking module as transit_gateway_id"
  value       = aws_ec2_transit_gateway.main.id
}

output "dr_tgw_id" {
  description = "ID of the Transit Gateway in the DR region"
  value       = aws_ec2_transit_gateway.dr.id
}

output "peering_attachment_id" {
  description = "ID of the TGW peering attachment between primary and DR"
  value       = aws_ec2_transit_gateway_peering_attachment.primary_to_dr.id
}

output "primary_tgw_route_table_id" {
  description = "ID of the primary TGW route table"
  value       = aws_ec2_transit_gateway_route_table.primary.id
}

output "dr_tgw_route_table_id" {
  description = "ID of the DR TGW route table"
  value       = aws_ec2_transit_gateway_route_table.dr.id
}
