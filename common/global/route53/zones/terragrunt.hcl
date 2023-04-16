include {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/route53/aws//modules/zones?version=2.10.2"
}

locals {
  domain_name = "runcloudone.com"
}

inputs = {
  zones = {
    public = {
      domain_name = local.domain_name
      comment     = "HostedZone created by Route53 Registrar"
      tags = {
        Name = local.domain_name
      }
    }
  }
}
