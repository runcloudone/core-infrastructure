data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "controller_task_execution_role_policy" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [aws_secretsmanager_secret.controller_password.arn, var.secretsmanager_kms_key_arn]
  }

  statement {
    actions = [
      "kms:Decrypt"
    ]
    resources = [var.secretsmanager_kms_key_arn]
  }
}

data "aws_iam_policy_document" "controller_task_role_policy" {
  statement {
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:ListClusters",
      "ecs:DescribeContainerInstances",
      "ecs:ListTaskDefinitions",
      "ecs:DescribeTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:ListTagsForResource"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecs:ListContainerInstances",
      "ecs:DescribeClusters"
    ]
    resources = [var.ecs_cluster_arn]
  }

  statement {
    actions = [
      "ecs:RunTask",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/*"]
    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [var.ecs_cluster_arn]
    }
  }

  statement {
    actions = [
      "ecs:StopTask",
      "ecs:DescribeTasks",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/*"]
    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [var.ecs_cluster_arn]
    }
  }

  statement {
    actions = [
      "iam:PassRole",
    ]
    resources = [aws_iam_role.agent_task_execution_role.arn, aws_iam_role.agent_task_role.arn]
  }

  statement {
    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems"
    ]
    resources = ["arn:${data.aws_partition.current.partition}:elasticfilesystem:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:file-system/*"]
  }

  statement {
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:elasticfilesystem:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:file-system/${module.efs.id}"]
    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values = [
        "arn:${data.aws_partition.current.partition}:elasticfilesystem:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:access-point/${module.efs.access_points[var.controller_name].id}"
      ]
    }
  }
}

resource "aws_iam_role" "contoller_task_execution_role" {
  name               = "${var.controller_name}-task-execution-role"
  description        = "Role used by the ECS agent to access AWS resources"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json

  tags = var.tags
}

resource "aws_iam_policy" "contoller_task_execution_role_policy" {
  name        = "${var.controller_name}-task-execution-role-policy"
  description = "Policy for Jenkins Controller task execution role"
  policy      = data.aws_iam_policy_document.controller_task_execution_role_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "contoller_task_execution_role_policy_attachment" {
  policy_arn = aws_iam_policy.contoller_task_execution_role_policy.arn
  role       = aws_iam_role.contoller_task_execution_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.contoller_task_execution_role.name
}

resource "aws_iam_role" "controller_task_role" {
  name                  = "${var.controller_name}-task-role"
  description           = "Role used by the Jenkins controller to access AWS resources"
  assume_role_policy    = data.aws_iam_policy_document.ecs_assume_role_policy.json
  force_detach_policies = true

  tags = var.tags
}

resource "aws_iam_policy" "controller_task_role_policy" {
  name        = "${var.controller_name}-task-role-policy"
  description = "Policy for Jenkins controller task role"
  policy      = data.aws_iam_policy_document.controller_task_role_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "controller_task_role_policy_attachment" {
  role       = aws_iam_role.controller_task_role.name
  policy_arn = aws_iam_policy.controller_task_role_policy.arn
}

resource "aws_iam_role" "agent_task_execution_role" {
  name               = "${var.agent_name}-task-execution-role"
  description        = "Role used by the ECS agent to access AWS resources"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "agent_ecs_task_execution_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.agent_task_execution_role.name
}

resource "aws_iam_role" "agent_task_role" {
  name                  = "${var.agent_name}-task-role"
  description           = "Role used by the Jenkins agent to access AWS resources"
  assume_role_policy    = data.aws_iam_policy_document.ecs_assume_role_policy.json
  force_detach_policies = true

  tags = var.tags
}

//TODO: Add policy for agent task role
