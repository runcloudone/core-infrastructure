module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "4.1.3"

  cluster_name = var.cluster_name

  cluster_configuration = {
    execute_command_configuration = {
      kms_key_id = var.kms_key_arn
      logging    = "OVERRIDE"
      log_configuration = {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_execute_command.name
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

  tags = merge(
    {
      Name = var.cluster_name
    },
    var.tags
  )
}

resource "aws_cloudwatch_log_group" "ecs_execute_command" {
  name              = "/aws/ecs/${var.cluster_name}/execute-command"
  retention_in_days = var.ecs_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(
    {
      Name = "${var.cluster_name}-log-group"
    },
    var.tags
  )
}
