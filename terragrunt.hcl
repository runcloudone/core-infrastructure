locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl", "${get_terragrunt_dir()}/common.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl", "${get_terragrunt_dir()}/account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl", "${get_terragrunt_dir()}/region.hcl"))

  name_prefix    = local.common_vars.locals.name_prefix
  default_region = local.common_vars.locals.default_region
  account_id     = local.account_vars.locals.account_id
  account_name   = local.account_vars.locals.account_name
  aws_region     = local.region_vars.locals.aws_region
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region              = "${local.aws_region}"
  allowed_account_ids = ["${local.account_id}"]
  default_tags {
    tags = var.default_tags
  }
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags for AWS that will be attached to each resource"
}
EOF
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    encrypt                 = true
    bucket                  = lower("${local.name_prefix}-${local.account_name}-${local.aws_region}-terraform-state")
    key                     = "${path_relative_to_include()}/terraform.tfstate"
    region                  = local.default_region
    dynamodb_table          = lower("${local.name_prefix}-${local.account_name}-terraform-state-locks")
    skip_bucket_root_access = true
  }
}

inputs = {
  name_prefix  = local.name_prefix
  account_name = local.account_name
  account_id   = local.account_id
  aws_region   = local.aws_region
  default_tags = {
    "Terraform"  = "true",
    "Team"       = "infraops",
    "OwnerEmail" = "ilya.melnik.svc@gmail.com"
    "Account"    = local.account_name
  }
}
