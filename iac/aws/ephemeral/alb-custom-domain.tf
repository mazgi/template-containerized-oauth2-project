# -----------------------------------------------------------------------------
# Custom domain setup for ECS Express Gateway ALBs
#
# The aws_ecs_express_gateway_service resource does not expose load balancer,
# listener, or target group ARNs. We use the awscc provider's data source to
# read ecs_managed_resource_arns which includes these ARNs.
# -----------------------------------------------------------------------------

data "awscc_ecs_express_gateway_service" "web" {
  id = aws_ecs_express_gateway_service.web.service_arn
}

data "awscc_ecs_express_gateway_service" "backend" {
  id = aws_ecs_express_gateway_service.backend.service_arn
}

# --- Web service ---

resource "aws_lb_listener_certificate" "web" {
  listener_arn    = data.awscc_ecs_express_gateway_service.web.ecs_managed_resource_arns.ingress_path.listener_arn
  certificate_arn = local.persistent.acm_wildcard_certificate_arn
}

resource "aws_lb_listener_rule" "web_custom_domain" {
  listener_arn = data.awscc_ecs_express_gateway_service.web.ecs_managed_resource_arns.ingress_path.listener_arn

  action {
    type             = "forward"
    target_group_arn = data.awscc_ecs_express_gateway_service.web.ecs_managed_resource_arns.ingress_path.target_group_arns[0]
  }

  condition {
    host_header {
      values = ["web.${local.persistent.dns_zone_name}"]
    }
  }
}

# --- Backend service ---

resource "aws_lb_listener_certificate" "backend" {
  listener_arn    = data.awscc_ecs_express_gateway_service.backend.ecs_managed_resource_arns.ingress_path.listener_arn
  certificate_arn = local.persistent.acm_wildcard_certificate_arn
}

resource "aws_lb_listener_rule" "backend_custom_domain" {
  listener_arn = data.awscc_ecs_express_gateway_service.backend.ecs_managed_resource_arns.ingress_path.listener_arn

  action {
    type             = "forward"
    target_group_arn = data.awscc_ecs_express_gateway_service.backend.ecs_managed_resource_arns.ingress_path.target_group_arns[0]
  }

  condition {
    host_header {
      values = ["backend.${local.persistent.dns_zone_name}"]
    }
  }
}
