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
  bucket = "www.dannykweb.com"
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

# Upload error.html file
resource "aws_s3_object" "error_file" {
  bucket        = aws_s3_bucket.www.id
  key           = "error.html"
  source        = "error.html"
  etag          = filemd5("error.html")
  content_type  = "text/html"
  cache_control = "no-cache"
}

resource "aws_s3_object" "about_page" {
  bucket        = aws_s3_bucket.www.id
  key           = "about"
  source        = "about.html"
  etag          = filemd5("about.html")
  content_type  = "text/html"
  cache_control = "no-cache"
}

resource "aws_s3_object" "contact_page" {
  bucket        = aws_s3_bucket.www.id
  key           = "contact"
  source        = "contact.html"
  etag          = filemd5("contact.html")
  content_type  = "text/html"
  cache_control = "no-cache"
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
  bucket = "dannykweb.com"
}

# Configure naked domain bucket to redirect to www
resource "aws_s3_bucket_website_configuration" "naked" {
  bucket = aws_s3_bucket.naked.id

  redirect_all_requests_to {
    host_name = aws_s3_bucket_website_configuration.www.website_endpoint
    protocol  = "http"
  }
}
