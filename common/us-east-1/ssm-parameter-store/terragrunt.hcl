include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::git@github.com:cloudposse/terraform-aws-ssm-parameter-store.git//.?ref=0.10.0"
}

dependency "vpc_main" {
  config_path                             = "../vpc/main"
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
  config_path                             = "../../global/route53/zones"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    route53_zone_name = {
      public = "example.com"
    }
    route53_zone_zone_id = {
      public = "Z3P5QSUBK4POTI"
    }
  }
}

dependency "ecs_main" {
  config_path                             = "../ecs/main"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    cluster_arn  = "arn:aws:ecs:us-east-1:123456789012:cluster/ecs-cluster"
    cluster_name = "ecs-cluster"
  }
}

inputs = {
  parameter_write = [
    {
      name = "/shared/infrastructure"
      value = jsonencode({
        vpc_id              = dependency.vpc_main.outputs.vpc_id
        public_subnets      = dependency.vpc_main.outputs.public_subnets
        private_subnets     = dependency.vpc_main.outputs.private_subnets
        database_subnets    = dependency.vpc_main.outputs.database_subnets
        elasticache_subnets = dependency.vpc_main.outputs.elasticache_subnets
        intra_subnets       = dependency.vpc_main.outputs.intra_subnets,
        root_domain         = dependency.route53_zones.outputs.route53_zone_name.public
        hosted_zone_id      = dependency.route53_zones.outputs.route53_zone_zone_id.public
        ecs_cluster_arn     = dependency.ecs_main.outputs.cluster_arn
        ecs_cluster_name    = dependency.ecs_main.outputs.cluster_name
      })
      type        = "String"
      overwrite   = "true"
      description = "Shared infrastructure configuration"
    }
  ]
}
