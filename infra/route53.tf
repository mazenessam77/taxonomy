###############################################################################
# Route 53 — DNS → CloudFront
###############################################################################

# Uncomment and configure once you have a hosted zone

# data "aws_route53_zone" "main" {
#   name         = "example.com"  # Your root domain
#   private_zone = false
# }
#
# resource "aws_route53_record" "app" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = var.domain_name
#   type    = "A"
#
#   alias {
#     name                   = aws_cloudfront_distribution.app.domain_name
#     zone_id                = aws_cloudfront_distribution.app.hosted_zone_id
#     evaluate_target_health = false
#   }
# }
#
# resource "aws_route53_record" "app_ipv6" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = var.domain_name
#   type    = "AAAA"
#
#   alias {
#     name                   = aws_cloudfront_distribution.app.domain_name
#     zone_id                = aws_cloudfront_distribution.app.hosted_zone_id
#     evaluate_target_health = false
#   }
# }
