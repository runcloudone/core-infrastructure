variable "cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
}

variable "capacity_provider_wight" {
  type = object({
    fargate      = number
    fargate_spot = number
  })
  description = "Weight of Fargate and Fargate Spot capacity providers"
  default = {
    fargate      = 100
    fargate_spot = 0
  }
}

variable "ecs_log_retention_days" {
  type        = number
  description = "Number of days to retain ECS logs"
  default     = 14
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN to use for encrypting resources"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources created by this module"
  default     = {}
}
