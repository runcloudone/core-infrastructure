include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "tfr:///terraform-aws-modules/kms/aws//.?version=1.5.0"
}

locals {
  name_prefix = include.root.inputs.name_prefix
  account_id  = include.root.inputs.account_id
  region      = include.root.inputs.aws_region
  name        = "${local.name_prefix}-${local.region}-shared-key"
}

inputs = {
  description = "Shared KMS key for ${local.region} region"
  aliases     = [local.name]

  # Key policy
  key_statements = [
    {
      sid = "AllowCloudWatchToEncryptLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${local.region}.amazonaws.com"]
        }
      ]

      conditions = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values = [
            "arn:aws:logs:${local.region}:${local.account_id}:log-group:*",
          ]
        }
      ]
    }
  ]

  tags = {
    Name = local.name
  }
}
