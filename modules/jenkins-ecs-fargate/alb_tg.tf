resource "aws_lb_target_group" "controller" {
  name        = "${var.controller_name}-tg"
  port        = var.controller_container_definition.http_port
  target_type = "ip"
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    path                = var.controller_health_check.path
    timeout             = var.controller_health_check.timeout
    interval            = var.controller_health_check.interval
    healthy_threshold   = var.controller_health_check.healthy_threshold
    unhealthy_threshold = var.controller_health_check.unhealthy_threshold
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "controller" {
  listener_arn = var.alb_https_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.controller.arn
  }

  condition {
    host_header {
      values = ["${var.subdomain}.${var.route53_zone_name}"]
    }
  }

  tags = var.tags
}
