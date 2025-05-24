terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "ap-northeast-1"
}

locals {
  lambda_code = <<-EOF
    import boto3

    def lambda_handler(event, context):
        s3 = boto3.client('s3')
        bucket_name = "${aws_s3_bucket.demo.bucket}"
        key = "test.txt"
        response = s3.get_object(Bucket=bucket_name, Key=key)
        content = response['Body'].read().decode('utf-8')
        print(content)
  EOF
}

resource "local_file" "lambda_code" {
  content  = local.lambda_code
  filename = "${path.module}/index.py"
}

resource "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = local_file.lambda_code.filename
  output_path = "${path.module}/lambda.zip"
}

# VPC setup: Create a VPC to host resources.
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

# Subnet: Private subnet within the VPC for Lambda function.
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet"
  }
}

# YOU CAN COMMENT OUT BELOW AND LAMBDA WOULD NOT WORK WITHOUT GATEWAY ENDPOINT
# Route Table: Associate private subnet with route table.
# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.main.id
#   tags = {
#     Name = "private-rt"
#   }
# }

# YOU CAN COMMENT OUT BELOW AND LAMBDA WOULD NOT WORK WITHOUT GATEWAY ENDPOINT
# resource "aws_route_table_association" "private_assoc" {
#   subnet_id      = aws_subnet.private.id
#   route_table_id = aws_route_table.private.id
# }

# YOU CAN COMMENT OUT BELOW AND LAMBDA WOULD NOT WORK WITHOUT GATEWAY ENDPOINT
# Gateway Endpoint for S3: Enables private S3 access from the VPC without internet or NAT gateway.
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.ap-northeast-1.s3"
#   route_table_ids   = [aws_route_table.private.id]
#   vpc_endpoint_type = "Gateway"
#   tags = {
#     Name = "s3-gateway-endpoint"
#   }
# }


# IF ABOVE aws_vpc_endpoint (gateway endpoint), aws_route_table, and aws_route_table_association ARE COMMENTED OUT, THEN BELOW CODE WILL NOT WORK AND YOU WILL GET BELOW ERROR
# EVEN THOUGH LAMBDA HAS S3 ACCESS IAM ROLE ATTACHED. SINCE  LAMBDA IS RUNNING IN PRIVATE SUBNET THE REQUEST TO S3 WILL FAIL.
# Status: Failed
# Test Event Name: hello-world

# Response:
# {
#   "errorMessage": "2025-05-24T06:16:18.433Z 12fe65a5-bd15-41b5-a712-b65af7a47bb9 Task timed out after 3.01 seconds"
# }

# Random String: Generate a unique suffix for the S3 bucket name.
resource "random_string" "bucket_suffix" {
  length  = 8
  upper   = false
  special = false
}

# S3 Bucket: Create an S3 bucket with a unique name for Lambda to access.
resource "aws_s3_bucket" "demo" {
  bucket = "demo-bucket-${random_string.bucket_suffix.result}"
  tags = {
    Name = "demo-bucket"
  }
}

# S3 Object: Upload a sample object into the S3 bucket.
resource "aws_s3_object" "demo_file" {
  bucket  = aws_s3_bucket.demo.id
  key     = "test.txt"
  content = "This is a test file for Lambda access."
  acl     = "private"
}

# IAM Role for Lambda: Allows Lambda function to access S3 bucket and objects via the gateway endpoint.
resource "aws_iam_role" "lambda_role" {
  name = "lambda-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for S3 Access: Allow GetObject and ListBucket on the created S3 bucket and its objects only.
resource "aws_iam_policy" "lambda_s3_access" {
  name        = "lambda-s3-access"
  description = "Allow Lambda function to access the demo S3 bucket and its objects via endpoint"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.demo.arn,
          "${aws_s3_bucket.demo.arn}/*"
        ]
      }
    ]
  })
}

# Attach S3 access policy to Lambda role.
resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_access.arn
}

# Attach AWSLambdaVPCAccessExecutionRole managed policy for VPC access.
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda Function: Runs inside the private subnet, accessing the demo S3 bucket and object through the VPC endpoint.
resource "aws_lambda_function" "lambda" {
  function_name = "s3-access-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"

  filename         = archive_file.lambda_zip.output_path
  source_code_hash = archive_file.lambda_zip.output_base64sha256

  # Configure Lambda to run within the VPC private subnet and default security group.
  vpc_config {
    subnet_ids         = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.lambda_sg.id] # Add a security group for Lambda
  }

  # Inline comment: Lambda runs in VPC private subnet; no internet or NAT required due to S3 Gateway Endpoint.
  # This setup ensures Lambda can securely access the demo S3 bucket and objects without exposure to internet.
  
  tags = {
    Name = "s3-access-lambda"
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "lambda-sg"
  description = "Security group for Lambda function"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block] # Allow HTTPS traffic within the VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "lambda-sg"
  }
}


