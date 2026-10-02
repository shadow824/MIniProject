# Architecture

## Traffic path

`Internet -> CloudFront -> ALB -> EC2 -> RDS/EFS`

CloudFront adds `X-Origin-Verify`. The ALB returns `403` by default and forwards only when that header matches the generated secret.

## Network

- App VPC: `10.0.0.0/16`
- Public A: `10.0.1.0/24`, `us-east-1a`, ALB only
- Public B: `10.0.2.0/24`, `us-east-1b`, ALB only
- Private A: `10.0.11.0/24`, `us-east-1a`, EC2/RDS/EFS
- Private B: `10.0.12.0/24`, `us-east-1b`, EC2/RDS/EFS
- Tools VPC: `10.1.0.0/16`
- Tools A: `10.1.1.0/24`, `us-east-1a`, monitoring EC2

## Routing

The public route table has `0.0.0.0/0 -> Internet Gateway`.
The private route table has the local VPC route plus the S3 Gateway Endpoint route and the peering route to `10.1.0.0/16`. There is deliberately no NAT Gateway route.

## Why each resource sits where it does

- ALB is public because it is the internet-facing entry point.
- EC2 is private because users must not reach servers directly.
- RDS is private because the database is an internal dependency.
- EFS is private because shared application files do not need public access.
- Tools VPC is separate to demonstrate private cross-VPC connectivity through peering.
- VPC endpoints provide private AWS-service access without a NAT Gateway.
