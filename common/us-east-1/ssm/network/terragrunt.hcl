include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "git::git@github.com:cloudposse/terraform-aws-ssm-parameter-store.git//.?ref=0.10.0"
}

dependency "vpc" {
  config_path                             = "../../vpc"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    vpc_id = "vpc-12345678"
    public_subnets = [
      "subnet-12345678",
      "subnet-12345678",
      "subnet-12345678",
    ]
    private_subnets = [
      "subnet-12345678",
      "subnet-12345678",
      "subnet-12345678",
    ]
    database_subnets = [
      "subnet-12345678",
      "subnet-12345678",
      "subnet-12345678",
    ]
    elasticache_subnets = [
      "subnet-12345678",
      "subnet-12345678",
      "subnet-12345678",
    ]
    intra_subnets = [
      "subnet-12345678",
      "subnet-12345678",
      "subnet-12345678",
    ]
  }
}

dependency "route53_zones" {
  config_path                             = "../../../global/route53/zones"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    route53_zone_zone_id = {
      public = "Z3P5QSUBK4POTI"
    }
  }
}

locals {
  region = include.root.locals.aws_region
}

inputs = {
  parameter_write = [
    {
      name = "/${local.region}/infra/network"
      value = jsonencode({
        vpc_id              = dependency.vpc.outputs.vpc_id
        public_subnets      = dependency.vpc.outputs.public_subnets
        private_subnets     = dependency.vpc.outputs.private_subnets
        database_subnets    = dependency.vpc.outputs.database_subnets
        elasticache_subnets = dependency.vpc.outputs.elasticache_subnets
        intra_subnets       = dependency.vpc.outputs.intra_subnets,
        hosted_zone_id      = dependency.route53_zones.outputs.route53_zone_zone_id.public
      })
      type        = "String"
      overwrite   = "true"
      description = "Network configuration"
    }
  ]
}
