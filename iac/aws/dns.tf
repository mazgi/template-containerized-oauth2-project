# -----------------------------------------------------------------------------
# Route 53 — DNS zone for {app_unique_id}-aws.{base_domain_name}
# -----------------------------------------------------------------------------

resource "aws_route53_zone" "main" {
  name = "${var.app_unique_id}-aws.${var.base_domain_name}"
}
