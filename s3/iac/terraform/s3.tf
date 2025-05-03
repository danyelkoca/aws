resource "aws_s3_bucket" "example" {
  // make sure this bucket name is unique
  bucket = "tf-dannykbucket"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
