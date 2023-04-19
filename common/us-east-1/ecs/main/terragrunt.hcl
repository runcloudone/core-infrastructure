include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "../../../../modules//ecs-fargate-cluster"
}

dependency "common_kms_key" {
  config_path                             = "../../kms/common"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}

dependency "vpc_main" {
  config_path                             = "../../vpc/main"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    vpc_id = "vpc-12345678"
  }
}

dependency "route53_zones" {
  config_path                             = "../../../global/route53/zones"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    route53_zone_name = {
      public = "example.com"
    }
  }
}

locals {
  cluster_name = "${basename(get_terragrunt_dir())}-ecs-fargate-cluster"
}

inputs = {
  cluster_name          = local.cluster_name
  vpc_id                = dependency.vpc_main.outputs.vpc_id
  private_dns_namespace = replace(dependency.route53_zones.outputs.route53_zone_name.public, "com", "internal")
  log_group_kms_key_arn = dependency.common_kms_key.outputs.key_arn
  capacity_provider_wight = {
    fargate      = 10
    fargate_spot = 90
  }
}
