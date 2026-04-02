# -----------------------------------------------------------------------------
# Route 53 — DNS records for backend and web services
# Zone is created in the persistent layer.
# Uses ALIAS A records pointing to the ECS Express Gateway ALBs.
# -----------------------------------------------------------------------------

data "aws_lb" "web" {
  arn = data.awscc_ecs_express_gateway_service.web.ecs_managed_resource_arns.ingress_path.load_balancer_arn
}

data "aws_lb" "backend" {
  arn = data.awscc_ecs_express_gateway_service.backend.ecs_managed_resource_arns.ingress_path.load_balancer_arn
}

resource "aws_route53_record" "web" {
  zone_id = local.persistent.dns_zone_id
  name    = "web.${local.persistent.dns_zone_name}"
  type    = "A"

  alias {
    name                   = data.aws_lb.web.dns_name
    zone_id                = data.aws_lb.web.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "backend" {
  zone_id = local.persistent.dns_zone_id
  name    = "backend.${local.persistent.dns_zone_name}"
  type    = "A"

  alias {
    name                   = data.aws_lb.backend.dns_name
    zone_id                = data.aws_lb.backend.zone_id
    evaluate_target_health = true
  }
}
