# -----------------------------------------------------------------------------
# Custom domain setup for ECS Express Gateway ALBs
#
# The aws_ecs_express_gateway_service resource does not expose load balancer,
# listener, or target group ARNs. We look them up via data sources using the
# endpoint hostname that the resource does export.
# -----------------------------------------------------------------------------

locals {
  # Extract hostname from the endpoint URL (strip https:// prefix)
  web_endpoint_host     = trimprefix(aws_ecs_express_gateway_service.web.ingress_paths[0].endpoint, "https://")
  backend_endpoint_host = trimprefix(aws_ecs_express_gateway_service.backend.ingress_paths[0].endpoint, "https://")
}

# --- Web service ---

data "aws_lb" "web" {
  tags = {
    "ecs:express:service-arn" = aws_ecs_express_gateway_service.web.service_arn
  }
}

data "aws_lb_listener" "web_https" {
  load_balancer_arn = data.aws_lb.web.arn
  port              = 443
}

data "aws_lb_target_group" "web" {
  tags = {
    "ecs:express:service-arn" = aws_ecs_express_gateway_service.web.service_arn
  }
}

resource "aws_lb_listener_certificate" "web" {
  listener_arn    = data.aws_lb_listener.web_https.arn
  certificate_arn = local.persistent.acm_wildcard_certificate_arn
}

resource "aws_lb_listener_rule" "web_custom_domain" {
  listener_arn = data.aws_lb_listener.web_https.arn

  action {
    type             = "forward"
    target_group_arn = data.aws_lb_target_group.web.arn
  }

  condition {
    host_header {
      values = ["web.${local.persistent.dns_zone_name}"]
    }
  }
}

# --- Backend service ---

data "aws_lb" "backend" {
  tags = {
    "ecs:express:service-arn" = aws_ecs_express_gateway_service.backend.service_arn
  }
}

data "aws_lb_listener" "backend_https" {
  load_balancer_arn = data.aws_lb.backend.arn
  port              = 443
}

data "aws_lb_target_group" "backend" {
  tags = {
    "ecs:express:service-arn" = aws_ecs_express_gateway_service.backend.service_arn
  }
}

resource "aws_lb_listener_certificate" "backend" {
  listener_arn    = data.aws_lb_listener.backend_https.arn
  certificate_arn = local.persistent.acm_wildcard_certificate_arn
}

resource "aws_lb_listener_rule" "backend_custom_domain" {
  listener_arn = data.aws_lb_listener.backend_https.arn

  action {
    type             = "forward"
    target_group_arn = data.aws_lb_target_group.backend.arn
  }

  condition {
    host_header {
      values = ["backend.${local.persistent.dns_zone_name}"]
    }
  }
}
