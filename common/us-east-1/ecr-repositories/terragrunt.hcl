include {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/ecr/aws//wrappers?version=1.6.0"
}

dependency "common_kms_key" {
  config_path                             = "../kms/common"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}

inputs = {
  items = {
    jenkins_controller = {
      repository_name                 = "jenkins-controller"
      repository_image_tag_mutability = "MUTABLE"

      repository_encryption_type = "KMS"
      repository_kms_key         = dependency.common_kms_key.outputs.key_arn

      #TODO: Update Reader and Writer ARNs or provide custom policy

      repository_lifecycle_policy = jsonencode({
        rules = [
          {
            rulePriority = 1
            description  = "Keep only the 3 most recent images"
            selection = {
              tagStatus   = "any"
              countType   = "imageCountMoreThan"
              countNumber = 3
            }
            action = {
              type = "expire"
            }
          }
        ]
      })
    }
  }
}
