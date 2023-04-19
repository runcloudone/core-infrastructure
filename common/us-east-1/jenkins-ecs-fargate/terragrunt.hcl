include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules//jenkins-ecs-fargate"
}

dependency "ecs_main" {
  config_path                             = "../ecs/main"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    cluster_arn             = "arn:aws:ecs:us-east-1:123456789012:cluster/ecs-cluster"
    cluster_name            = "fake-ecs-cluster"
    cloudmap_namespace_id   = "fake-cloudmap-namespace-id"
    cloudmap_namespace_name = "fake-cloudmap-namespace-name"
  }
}

dependency "vpc_main" {
  config_path                             = "../vpc/main"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    vpc_id = "vpc-12345678"
    private_subnets = [
      "subnet-12345678",
      "subnet-12345678",
      "subnet-12345678",
    ]
  }
}

dependency "http_https_common_sg" {
  config_path                             = "../sg/http-https-common"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    security_group_id = "sg-12345678"
  }
}

dependency "ecs_common_alb" {
  config_path                             = "../alb/ecs-common"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    lb_dns_name = "fake-dns-name"
    lb_zone_id  = "fake-zone-id"
    https_listener_arns = [
      "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/lb-name/1234567890123456/1234567890123456",
    ]
  }
}

dependency "route53_zones" {
  config_path                             = "../../global/route53/zones"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    route53_zone_name = {
      public = "example.com"
    }
  }
}

dependency "common_kms_key" {
  config_path                             = "../kms/common"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}

inputs = {
  ecs_cluster_arn         = dependency.ecs_main.outputs.cluster_arn
  ecs_cluster_name        = dependency.ecs_main.outputs.cluster_name
  cloudmap_namespace_id   = dependency.ecs_main.outputs.cloudmap_namespace_id
  cloudmap_namespace_name = dependency.ecs_main.outputs.cloudmap_namespace_name
  controller_name         = "jenkins-controller"
  agent_name              = "jenkins-agent"
  controller_container_definition = {
    name            = "app"
    container_image = "787096050701.dkr.ecr.us-east-1.amazonaws.com/jenkins-controller:latest"
    http_port       = 8080
    jnlp_port       = 50000
    environment = {
      admin_username              = "runcloudone"
      admin_email                 = "ilya.melnik.svc@gmail.com"
      agent_image                 = "jenkins/inbound-agent:latest"
      retain_ecs_agents           = true
      ecs_agent_retention_timeout = 10
      pipeline_commons_repo       = "https://github.com/runcloudone/jenkins-pipeline-commons.git"
    }
  }

  vpc_id                = dependency.vpc_main.outputs.vpc_id
  private_subnets       = dependency.vpc_main.outputs.private_subnets
  alb_security_group_id = dependency.http_https_common_sg.outputs.security_group_id

  alb_dns_name           = dependency.ecs_common_alb.outputs.lb_dns_name
  alb_zone_id            = dependency.ecs_common_alb.outputs.lb_zone_id
  alb_https_listener_arn = dependency.ecs_common_alb.outputs.https_listener_arns[0]
  route53_zone_name      = dependency.route53_zones.outputs.route53_zone_name.public

  secretsmanager_kms_key_arn = dependency.common_kms_key.outputs.key_arn
  efs_kms_key_arn            = dependency.common_kms_key.outputs.key_arn
  log_group_kms_key_arn      = dependency.common_kms_key.outputs.key_arn
}
