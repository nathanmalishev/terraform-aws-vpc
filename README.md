# Terraform module: AWS VPC

Creates a VPC with private and public subnets in each availability zone for the specified region.  Also starts a NAT instance to allow outside communication from private subnets.

Required variables are `vpc_name` and `vpc_region`.
