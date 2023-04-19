module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "4.1.3"

  cluster_name = var.cluster_name

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.execute_command.name
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = var.capacity_provider_wight.fargate
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = var.capacity_provider_wight.fargate_spot
      }
    }
  }

  cluster_settings = {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

resource "aws_service_discovery_private_dns_namespace" "ecs" {
  name        = var.private_dns_namespace
  vpc         = var.vpc_id
  description = "Service Discovery namespace for ${var.cluster_name}"

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "execute_command" {
  name              = "/aws/ecs/${var.cluster_name}/execute-command"
  retention_in_days = var.ecs_log_retention_days
  kms_key_id        = var.log_group_kms_key_arn

  tags = var.tags
}
