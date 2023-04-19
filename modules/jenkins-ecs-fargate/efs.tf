locals {
  efs_name = "${var.controller_name}-efs"
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "1.1.1"

  # File system
  name           = local.efs_name
  creation_token = local.efs_name
  encrypted      = true
  kms_key_arn    = var.efs_kms_key_arn

  performance_mode                = var.efs_performance_mode
  throughput_mode                 = var.efs_throughput_mode
  provisioned_throughput_in_mibps = var.efs_provisioned_throughput_in_mibps

  lifecycle_policy = {
    transition_to_ia                    = var.lifecycle_policy.transition_to_ia
    transition_to_primary_storage_class = var.lifecycle_policy.transition_to_primary_storage_class
  }

  # Mount targets / security group
  mount_targets                  = { for k, v in zipmap(local.azs, var.private_subnets) : k => { subnet_id = v } }
  security_group_name            = local.efs_name
  security_group_use_name_prefix = true
  security_group_description     = "Security group for EFS allowing access to port 2049/TCP"
  security_group_vpc_id          = var.vpc_id
  security_group_rules = {
    controller = {
      # relying on the defaults provdied for EFS/NFS (2049/TCP + ingress)
      description              = "Allow Jenkins Controller to access EFS"
      source_security_group_id = module.controller_sg.security_group_id
    }
  }

  # Access point(s)
  access_points = {
    tostring(var.controller_name) = {
      posix_user = {
        gid = 1000
        uid = 1000
      }
      root_directory = {
        // TODO: Make this configurable
        path = "/jenkins"
        creation_info = {
          owner_gid   = 1000
          owner_uid   = 1000
          permissions = "755"
        }
      }
    }
  }

  // TODO: Add backup policy

  tags = var.tags
}
