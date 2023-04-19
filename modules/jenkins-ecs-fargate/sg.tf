module "controller_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.2"

  name        = "${var.controller_name}-sg"
  description = "Security group for Jenkins ECS service"
  vpc_id      = var.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = var.controller_container_definition.http_port
      to_port                  = var.controller_container_definition.http_port
      protocol                 = "tcp"
      description              = "Allow ALB to access Jenkins ECS service"
      source_security_group_id = var.alb_security_group_id
    },
    {
      from_port                = var.controller_container_definition.http_port
      to_port                  = var.controller_container_definition.http_port
      protocol                 = "tcp"
      description              = "Allow Jenkins agents to access Jenkins ECS service"
      source_security_group_id = module.agent_sg.security_group_id
    },
    {
      from_port                = var.controller_container_definition.jnlp_port
      to_port                  = var.controller_container_definition.jnlp_port
      protocol                 = "tcp"
      description              = "Allow Jenkins agents to access Jenkins ECS service"
      source_security_group_id = module.agent_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]

  tags = var.tags
}

module "agent_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.2"

  name        = "${var.agent_name}-sg"
  description = "Security group for Jenkins agents"
  vpc_id      = var.vpc_id

  egress_rules = ["all-all"]

  tags = var.tags
}
