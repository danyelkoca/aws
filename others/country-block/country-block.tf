# WIP

# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-1"
}

# -----------------------------------------------------------------------------
# Geo-blocking Options in AWS:
#
# 1. CloudFront Geo-restriction (Simple, Cost-effective)
#    - Included in CloudFront pricing
#    - Country-level blocking only
#    - Returns 403 error for blocked countries
#    - Cannot combine with other criteria
#    - Good for simple country blocking needs
#
# 2. WAF Geo-match (Advanced, More Expensive)
#    - Additional WAF pricing applies
#    - Can combine with other WAF rules (IP, rate limiting, etc.)
#    - More control over response
#    - Can apply to ALB, API Gateway, AppSync, etc.
#    - Better for complex security requirements
# -----------------------------------------------------------------------------

# Create S3 bucket
resource "aws_s3_bucket" "website" {
  bucket_prefix = "country-block-demo-"
}

# Enable website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
}

# Upload index.html to the bucket
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  content      = <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>CloudFront Geo-blocking Demo</title>
</head>
<body>
    <h1>Welcome to CloudFront Geo-blocking Demo</h1>
    <p>This page is served through CloudFront with geo-blocking enabled.</p>
    <p>Access is blocked for visitors from China (CN) and Russia (RU).</p>
</body>
</html>
EOF
  content_type = "text/html"
}

# Create Origin Access Control for CloudFront
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-oac"
  description                       = "Origin Access Control for S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Create CloudFront distribution
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "Geo-blocking demo distribution"

  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = ["CN", "RU"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Create bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}

# Output the CloudFront URL
output "cloudfront_url" {
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
  description = "URL of the CloudFront distribution"
}
