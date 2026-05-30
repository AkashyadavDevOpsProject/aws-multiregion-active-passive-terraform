# Module: transit-gateway

Provisions a pair of Transit Gateways (one per region) connected via TGW Peering, enabling private routing between the primary VPC (ap-south-1) and the DR VPC (ap-south-2).

## Architecture

```
ap-south-1 VPC ─── TGW (primary) ─── TGW Peering ─── TGW (DR) ─── ap-south-2 VPC
```

Both TGWs use custom route tables (default association/propagation disabled) so routing is fully explicit.

## Provider requirements

Requires two provider configurations — default for primary region and `aws.dr` alias for DR region:

```hcl
provider "aws" {
  profile = "personal"
  region  = "ap-south-1"
}

provider "aws" {
  alias   = "dr"
  profile = "personal"
  region  = "ap-south-2"
}
```

## Apply order dependency

The networking module accepts `transit_gateway_id = null` on first apply. After TGW is created, re-apply networking to add TGW routes to the private route tables. This two-pass pattern avoids a circular dependency between networking and TGW.

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `project` | string | yes | Project name prefix |
| `environment` | string | yes | Environment |
| `primary_region` | string | yes | Primary region (e.g., `ap-south-1`) |
| `dr_region` | string | yes | DR region (e.g., `ap-south-2`) |
| `amazon_side_asn` | number | no | Primary TGW BGP ASN, default `64512` |
| `dr_amazon_side_asn` | number | no | DR TGW BGP ASN, default `64513` |
| `primary_vpc_id` | string | yes | Primary VPC ID |
| `primary_vpc_cidr` | string | yes | Primary VPC CIDR |
| `primary_private_app_subnet_ids` | list(string) | yes | Subnets for TGW attachment in primary |
| `dr_vpc_id` | string | yes | DR VPC ID |
| `dr_vpc_cidr` | string | yes | DR VPC CIDR |
| `dr_private_app_subnet_ids` | list(string) | yes | Subnets for TGW attachment in DR |
| `tags` | map(string) | no | Common tags |

## Outputs

| Name | Description |
|---|---|
| `primary_tgw_id` | Passed back to networking module after first apply |
| `dr_tgw_id` | DR TGW ID |
| `peering_attachment_id` | TGW peering attachment ID |
