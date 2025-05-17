# Configure AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0-beta1"
    }
  }
}

# Default AWS provider configuration
provider "aws" {}

# Primary S3 bucket for www subdomain
resource "aws_s3_bucket" "www" {
  bucket = "www.<DOMAIN_NAME>"
}

resource "aws_s3_bucket_public_access_block" "www" {
  bucket                  = aws_s3_bucket.www.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "www" {
  bucket = aws_s3_bucket.www.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.www.arn}/*"
      },
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.www]
}

# Upload all files from the build folder to the www bucket
resource "aws_s3_bucket_object" "build_files" {
  for_each = fileset("app/build", "**/*")

  bucket = aws_s3_bucket.www.id
  key    = each.value
  source = "app/build/${each.value}"
  content_type = lookup({
    "html" = "text/html",
    "css"  = "text/css",
    "js"   = "application/javascript",
    "png"  = "image/png",
    "jpg"  = "image/jpeg",
    "jpeg" = "image/jpeg",
    "svg"  = "image/svg+xml",
    "json" = "application/json"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

# Configure www bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "www" {
  bucket = aws_s3_bucket.www.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Output for www bucket website endpoint
output "www_website_endpoint" {
  value = aws_s3_bucket_website_configuration.www.website_endpoint
}

# S3 bucket for naked domain (without www)
resource "aws_s3_bucket" "naked" {
  bucket = "<DOMAIN_NAME>"
}

# Configure naked domain bucket to redirect to www
resource "aws_s3_bucket_website_configuration" "naked" {
  bucket = aws_s3_bucket.naked.id

  redirect_all_requests_to {
    host_name = aws_s3_bucket_website_configuration.www.website_endpoint
    protocol  = "http"
  }
}
