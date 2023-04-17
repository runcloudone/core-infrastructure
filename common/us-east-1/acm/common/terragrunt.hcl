include {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/acm/aws//wrappers?version=4.3.2"
}

locals {
  runcloudone_domain_name = "runcloudone.com"
}

dependency "route53_zones" {
  config_path                             = "../../../global/route53/zones"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    route53_zone_zone_id = {
      public = "Z3P5QSUBK4POTI"
    }
  }
}

inputs = {
  items = {
    runcloudone_common = {
      domain_name = local.runcloudone_domain_name
      zone_id     = dependency.route53_zones.outputs.route53_zone_zone_id.public

      subject_alternative_names = [
        "*.${local.runcloudone_domain_name}"
      ]

      validation_method   = "DNS"
      wait_for_validation = true

      tags = {
        Name = local.runcloudone_domain_name
      }
    }
  }
}
