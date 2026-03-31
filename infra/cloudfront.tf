###############################################################################
# CloudFront CDN → ALB Origin
###############################################################################

# This CloudFront distribution is created AFTER the ALB is provisioned
# by the AWS Load Balancer Controller. You must update the origin domain
# with the actual ALB DNS name after first deployment.
#
# To get the ALB DNS:
#   kubectl get ingress taxonomy-ingress -n taxonomy -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

resource "aws_cloudfront_distribution" "app" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${local.name} CDN distribution"
  default_root_object = ""
  aliases             = [var.domain_name]
  price_class         = "PriceClass_100"

  origin {
    # Replace with actual ALB DNS after first deployment
    domain_name = "REPLACE_WITH_ALB_DNS.us-east-1.elb.amazonaws.com"
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # ── Default behavior: dynamic requests → ALB ──
  default_cache_behavior {
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["Host", "Origin", "Authorization"]
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # ── Static assets: long cache ──
  ordered_cache_behavior {
    path_pattern           = "/_next/static/*"
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 86400
    default_ttl = 604800
    max_ttl     = 31536000
  }

  # ── Public assets: medium cache ──
  ordered_cache_behavior {
    path_pattern           = "/images/*"
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 3600
    default_ttl = 86400
    max_ttl     = 604800
  }

  # ── SSL Certificate (must be in us-east-1 for CloudFront) ──
  viewer_certificate {
    acm_certificate_arn      = var.cloudfront_acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.tags
}

###############################################################################
# Variable for CloudFront ACM cert (must be us-east-1)
###############################################################################

variable "cloudfront_acm_certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront SSL"
  type        = string
  default     = "arn:aws:acm:us-east-1:541405370428:certificate/PENDING"
}
