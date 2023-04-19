resource "random_password" "controller_password" {
  length = 16
}

resource "aws_secretsmanager_secret" "controller_password" {
  name                    = "/jenkins/controller/password"
  description             = "Initial admin password for Jenkins"
  kms_key_id              = var.secretsmanager_kms_key_arn
  recovery_window_in_days = 0

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "controller_password" {
  secret_id     = aws_secretsmanager_secret.controller_password.id
  secret_string = random_password.controller_password.result
}

resource "aws_cloudwatch_log_group" "controller" {
  name              = "/aws/ecs/${var.ecs_cluster_name}/jenkins/controller"
  retention_in_days = var.controller_log_retention_days
  kms_key_id        = var.log_group_kms_key_arn

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "agent" {
  name              = "/aws/ecs/${var.ecs_cluster_name}/jenkins/agent"
  retention_in_days = var.controller_log_retention_days
  kms_key_id        = var.log_group_kms_key_arn

  tags = var.tags
}

resource "aws_ecs_task_definition" "controller" {
  family = var.controller_name

  execution_role_arn = aws_iam_role.contoller_task_execution_role.arn
  task_role_arn      = aws_iam_role.controller_task_role.arn

  cpu                      = var.contoller_resources.cpu
  memory                   = var.contoller_resources.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  volume {
    name = local.efs_name

    efs_volume_configuration {
      file_system_id     = module.efs.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = module.efs.access_points[var.controller_name].id
        iam             = "ENABLED"
      }
    }
  }

  // TODO: Refactor container_definitions block
  container_definitions = jsonencode(
    [
      {
        name      = var.controller_container_definition.name
        image     = var.controller_container_definition.container_image
        essential = true
        mountPoints = [
          {
            sourceVolume = local.efs_name
            // TODO: Adjust containerPath to exclude the jenkins.yaml file
            containerPath = "/var/jenkins_home"
          },
        ]
        portMappings = [
          {
            containerPort = var.controller_container_definition.http_port
          },
          {
            containerPort = var.controller_container_definition.jnlp_port
          },
        ]
        environment = [
          {
            name  = "ADMIN_USERNAME"
            value = var.controller_container_definition.environment.admin_username
          },
          {
            name  = "ADMIN_EMAIL"
            value = var.controller_container_definition.environment.admin_email
          },
          {
            name  = "JENKINS_URL"
            value = "https://${var.subdomain}.${var.route53_zone_name}"
          },
          {
            name  = "ECS_AGENT_CLUSTER"
            value = var.ecs_cluster_arn
          },
          {
            name  = "AWS_REGION"
            value = data.aws_region.current.name
          },
          {
            name  = "RETAIN_ECS_AGENTS"
            value = tostring(var.controller_container_definition.environment.retain_ecs_agents)
          },
          {
            name  = "ECS_AGENT_RETENTION_TIMEOUT"
            value = tostring(var.controller_container_definition.environment.ecs_agent_retention_timeout)
          },
          {
            name  = "JENKINS_CLOUD_MAP_NAME"
            value = "${var.subdomain}.${var.cloudmap_namespace_name}"
          },
          {
            name  = "HTTP_PORT"
            value = tostring(var.controller_container_definition.http_port)
          },
          {
            name  = "AGENT_IMAGE"
            value = var.controller_container_definition.environment.agent_image
          },
          {
            name  = "SUBNET_IDS"
            value = join(",", var.private_subnets)
          },
          {
            name  = "SECURITY_GROUP_IDS"
            value = module.agent_sg.security_group_id
          },
          {
            name  = "EXECUTION_ROLE_ARN"
            value = aws_iam_role.agent_task_execution_role.arn
          },
          {
            name  = "TASK_ROLE_ARN"
            value = aws_iam_role.agent_task_role.arn
          },
          {
            name  = "ECS_AGENT_LOG_GROUP"
            value = aws_cloudwatch_log_group.agent.name
          },
          {
            name  = "PIPELINE_COMMONS_REPO"
            value = var.controller_container_definition.environment.pipeline_commons_repo
          }
        ]
        secrets = [
          {
            name      = "ADMIN_PASSWORD"
            valueFrom = aws_secretsmanager_secret.controller_password.arn
          },
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.controller.name
            awslogs-region        = data.aws_region.current.name
            awslogs-stream-prefix = "${var.controller_name}-service"
          }
        }
      }
    ]
  )

  tags = var.tags
}

resource "aws_ecs_service" "controller" {
  name             = "${var.controller_name}-service"
  cluster          = var.ecs_cluster_arn
  task_definition  = aws_ecs_task_definition.controller.arn
  desired_count    = 1
  launch_type      = var.controller_fargate_launch_type
  platform_version = var.fargate_platform_version

  deployment_minimum_healthy_percent = var.controller_deployment_percentages.min
  deployment_maximum_percent         = var.controller_deployment_percentages.max

  service_registries {
    registry_arn = aws_service_discovery_service.controller.arn
    port         = var.controller_container_definition.jnlp_port
  }

  network_configuration {
    security_groups  = [module.controller_sg.security_group_id]
    subnets          = var.private_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.controller.arn
    container_name   = var.controller_container_definition.name
    container_port   = var.controller_container_definition.http_port
  }

  tags = var.tags

  depends_on = [
    module.efs
  ]
}

resource "aws_service_discovery_service" "controller" {
  name = var.subdomain

  dns_config {
    namespace_id   = var.cloudmap_namespace_id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = var.cloudmap_ttl_seconds
      type = "A"
    }

    dns_records {
      ttl  = var.cloudmap_ttl_seconds
      type = "SRV"
    }
  }

  health_check_custom_config {
    failure_threshold = var.cloudmap_failure_threshold
  }

  tags = var.tags
}
