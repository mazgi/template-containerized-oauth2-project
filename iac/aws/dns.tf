# -----------------------------------------------------------------------------
# Route 53 — DNS zone for aws.{app_unique_id}.{base_domain_name}
# -----------------------------------------------------------------------------

resource "aws_route53_zone" "main" {
  name = "aws.${var.app_unique_id}.${var.base_domain_name}"
}
