include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws//.?version=4.0.1"
}

locals {
  region = include.root.inputs.aws_region
  name   = "${basename(get_terragrunt_dir())}-vpc"
}

inputs = {
  name = local.name
  cidr = "10.0.0.0/16"

  azs                 = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets      = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets    = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  elasticache_subnets = ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]
  intra_subnets       = ["10.0.51.0/24", "10.0.52.0/24", "10.0.53.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  manage_default_network_acl = true
  default_network_acl_tags = {
    Name = "${local.name}-default"
  }

  manage_default_route_table = true
  default_route_table_tags = {
    Name = "${local.name}-default"
  }

  manage_default_security_group = true
  default_security_group_tags = {
    Name = "${local.name}-default"
  }
}
