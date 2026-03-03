# -----------------------------------------------------------------------------
# Route 53 — DNS records for backend and web services
# Zone is created in the persistent layer.
# -----------------------------------------------------------------------------

resource "aws_route53_record" "backend" {
  zone_id = local.persistent.dns_zone_id
  name    = "backend.${local.persistent.dns_zone_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_ecs_express_gateway_service.backend.ingress_paths[0].endpoint]
}

resource "aws_route53_record" "web" {
  zone_id = local.persistent.dns_zone_id
  name    = "web.${local.persistent.dns_zone_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_ecs_express_gateway_service.web.ingress_paths[0].endpoint]
}
