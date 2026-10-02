# CloudFront creation is optional because AWS may return 403 until the account
# is verified for new CloudFront resources. Set enable_cloudfront=true after
# AWS Support/account verification is complete.
resource "aws_cloudfront_distribution" "app" {
  count = var.enable_cloudfront ? 1 : 0

  enabled         = true
  is_ipv6_enabled = true
  comment         = "DEPI secure platform CloudFront front door"

  origin {
    domain_name = aws_lb.app.dns_name
    origin_id   = "depi-sec-alb-origin"

    custom_header {
      name  = "X-Origin-Verify"
      value = random_password.origin_header.result
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "depi-sec-alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_100"

  tags = { Name = "depi-sec-cloudfront" }

  depends_on = [aws_lb_listener_rule.cloudfront_only]
}

# CloudFront Standard Logging v2.
# The destination policy resource is intentionally omitted: the CloudFront
# delivery source and S3 destination are in the same AWS account. AWS requires
# PutDeliveryDestinationPolicy for cross-account delivery, not same-account
# delivery. The S3 bucket policy below grants the delivery service its access.
resource "aws_cloudwatch_log_delivery_source" "cloudfront" {
  count = var.enable_cloudfront ? 1 : 0

  name         = "depi-sec-cloudfront-access-logs"
  log_type     = "ACCESS_LOGS"
  resource_arn = aws_cloudfront_distribution.app[0].arn
}

resource "aws_cloudwatch_log_delivery_destination" "cloudfront_s3" {
  count = var.enable_cloudfront ? 1 : 0

  name          = "depi-sec-cloudfront-s3-destination"
  output_format = "json"

  delivery_destination_configuration {
    destination_resource_arn = aws_s3_bucket.logs.arn
  }
}

resource "aws_cloudwatch_log_delivery" "cloudfront_s3" {
  count = var.enable_cloudfront ? 1 : 0

  delivery_source_name     = aws_cloudwatch_log_delivery_source.cloudfront[0].name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.cloudfront_s3[0].arn

  s3_delivery_configuration {
    enable_hive_compatible_path = true
    suffix_path                 = "cloudfront/{DistributionId}/{yyyy}/{MM}/{dd}/{HH}"
  }

  depends_on = [aws_s3_bucket_policy.logs]
}
