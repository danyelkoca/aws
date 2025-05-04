terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.97.0"
    }
  }
}

resource "aws_s3_bucket" "default" {}


resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.default.id
  key    = "myfile.txt"
  source = "${path.module}/myfile.txt"
  etag   = filemd5("${path.module}/myfile.txt")
}
