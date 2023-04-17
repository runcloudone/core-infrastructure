include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws//.?version=4.17.2"
}

locals {
  prefix = include.root.inputs.prefix
  name   = "${local.prefix}-${basename(get_terragrunt_dir())}-sg"
}

dependency "vpc_main" {
  config_path                             = "../../vpc/main"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    vpc_id = "vpc-12345678"
  }
}

inputs = {
  name                = local.name
  description         = "Common security group with HTTP and HTTPS ingress rules"
  vpc_id              = dependency.vpc_main.outputs.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  egress_rules        = ["all-all"]
}
