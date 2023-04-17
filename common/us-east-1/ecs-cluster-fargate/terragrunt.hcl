include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "../../../modules//ecs-cluster-fargate"
}

dependency "common_kms_key" {
  config_path                             = "../kms/common"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}

locals {
  prefix       = include.root.inputs.prefix
  cluster_name = "${local.prefix}-${basename(get_terragrunt_dir())}"
}

inputs = {
  cluster_name = local.cluster_name
  kms_key_arn  = dependency.common_kms_key.outputs.key_arn
  capacity_provider_wight = {
    fargate      = 10
    fargate_spot = 90
  }
}
