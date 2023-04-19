variable "cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to use for resources"
}

variable "capacity_provider_wight" {
  type = object({
    fargate      = number
    fargate_spot = number
  })
  description = "Weight of Fargate and Fargate Spot capacity providers"
}

variable "private_dns_namespace" {
  type        = string
  description = "Service Discovery namespace for ECS services"
}

variable "ecs_log_retention_days" {
  type        = number
  description = "Number of days to retain ECS execution-command logs"
  default     = 14
}

variable "log_group_kms_key_arn" {
  type        = string
  description = "KMS key ARN to use for encrypting ECS execution-command logs"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources created by this module"
  default     = {}
}
