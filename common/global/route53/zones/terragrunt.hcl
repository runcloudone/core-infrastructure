include {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/route53/aws//modules/zones?version=2.10.2"
}

inputs = {
  zones = {
    public = {
      domain_name = "runcloudone.com"
      comment     = "HostedZone created by Route53 Registrar"
    }
  }
}
