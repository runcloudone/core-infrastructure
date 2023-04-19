variable "controller_name" {
  type        = string
  description = "A unique name for Jenkins controller"
}

variable "agent_name" {
  type        = string
  description = "A unique name for Jenkins agent"
}

variable "ecs_cluster_arn" {
  type        = string
  description = "The ARN of the ECS cluster to run the Jenkins controller task"
}

variable "ecs_cluster_name" {
  type        = string
  description = "The name of the ECS cluster to run the Jenkins controller task"
}

variable "controller_container_definition" {
  type = object({
    name            = string
    container_image = string
    http_port       = number
    jnlp_port       = number
    environment = object({
      admin_username              = string
      admin_email                 = string
      agent_image                 = string
      retain_ecs_agents           = bool
      ecs_agent_retention_timeout = number
      pipeline_commons_repo       = string
    })
  })
  description = "Container definition for the Jenkins controller"
}

variable "contoller_resources" {
  type = object({
    cpu    = number
    memory = number
  })
  description = "CPU and memory resources for the Jenkins controller"
  default = {
    cpu    = 1024
    memory = 2048
  }
}

variable "controller_fargate_launch_type" {
  type        = string
  description = "Launch type for the Jenkins controller"
  default     = "FARGATE"
}

variable "fargate_platform_version" {
  type        = string
  description = "Fargate platform version to use"
  default     = "LATEST"
}

variable "controller_deployment_percentages" {
  type = object({
    min = number
    max = number
  })
  description = "Minimum and maximum deployment percentages for the Jenkins controller"
  default = {
    min = 100
    max = 200
  }
}

variable "controller_health_check" {
  type = object({
    path                = string
    interval            = number
    timeout             = number
    healthy_threshold   = number
    unhealthy_threshold = number
  })
  description = "Health check configuration for the Jenkins controller"
  default = {
    path                = "/login"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 5
  }
}

variable "subdomain" {
  type        = string
  description = "Subdomain used to access Jenkins"
  default     = "jenkins"
}

variable "cloudmap_namespace_id" {
  type        = string
  description = "The ID of the CloudMap namespace to register the Jenkins service"
}

variable "cloudmap_namespace_name" {
  type        = string
  description = "The name of the CloudMap namespace to register the Jenkins service"
}

variable "cloudmap_ttl_seconds" {
  type        = number
  description = "The TTL for the DNS records created in the CloudMap namespace"
  default     = 60
}

variable "cloudmap_failure_threshold" {
  type        = number
  description = "The number of consecutive health checks. Maximum value of 10"
  default     = 5
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to use for resources"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnets to place workloads"
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID of the ALB shared for the ECS cluster"
}

variable "alb_dns_name" {
  type        = string
  description = "The DNS name of the load balancer"
}

variable "alb_zone_id" {
  type        = string
  description = "The zone_id of the load balancer to assist with creating DNS records"
}

variable "alb_https_listener_arn" {
  type        = string
  description = "The ARN of the HTTPS load balancer listeners created"
}

variable "route53_zone_name" {
  type        = string
  description = "Root domain name for the Jenkins controller"
}

variable "efs_performance_mode" {
  type        = string
  description = "The file system performance mode. Can be either `generalPurpose` or `maxIO`. Default is `generalPurpose`"
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  type        = string
  description = "Throughput mode for the file system. Defaults to `bursting`. Valid values: `bursting`, `provisioned`. When using `provisioned`, also set `provisioned_throughput_in_mibps`"
  default     = "bursting"
}

variable "efs_provisioned_throughput_in_mibps" {
  type        = number
  description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with `throughput_mode` set to `provisioned`"
  default     = null
}

variable "lifecycle_policy" {
  type = object({
    transition_to_ia                    = string
    transition_to_primary_storage_class = string
  })
  description = "Lifecycle policy for the EFS file system"
  default = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }
}

variable "controller_log_retention_days" {
  type        = number
  description = "Number of days to retain Jenkins controller logs"
  default     = 14
}

variable "secretsmanager_kms_key_arn" {
  type        = string
  description = "The ARN of the KMS key used to encrypt the secrets"
}

variable "log_group_kms_key_arn" {
  type        = string
  description = "The ARN of the KMS key used to encrypt the log groups"
}

variable "efs_kms_key_arn" {
  type        = string
  description = "The ARN of the KMS key used to encrypt the EFS file system"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources created by this module"
  default     = {}
}
