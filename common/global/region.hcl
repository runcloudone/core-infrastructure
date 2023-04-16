locals {
  aws_region = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals.default_region
}
