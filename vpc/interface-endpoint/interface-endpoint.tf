# -----------------------------------------------------------------------------
# VPC with Private-Only Access Pattern
# -----------------------------------------------------------------------------
# This configuration demonstrates a security pattern where EC2 instances:
# 1. Have NO internet access (no IGW, no NAT gateway)
# 2. Can still access AWS S3 service through VPC endpoints
# 3. Remain completely isolated from the public internet
# This is ideal for highly secure workloads that need AWS services but no internet

provider "aws" {
  region = "ap-northeast-1"
}

# VPC with DNS support enabled - required for VPC endpoints to work
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true  # Required for endpoint private DNS
  enable_dns_support   = true  # Required for endpoint DNS resolution

  tags = {
    Name = "endpoint-vpc"
  }
}

# Private subnet with NO internet access
# -----------------------------------------------------------------------------
# This subnet has:
# - No route to an Internet Gateway (IGW)
# - No route to a NAT Gateway
# - Only local VPC routes and VPC endpoint routes
# This means instances in this subnet:
# - Cannot access the internet
# - Cannot be accessed from the internet
# - Can only access S3 through the VPC endpoint
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "private-subnet"
  }
}

# Private Route Table
# -----------------------------------------------------------------------------
# This route table only has:
# 1. Local VPC routes (automatically added)
# 2. S3 endpoint route (automatically added by the Gateway endpoint)
# NO routes to internet via IGW or NAT = true privacy
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-rt"
  }
}

# Associate private subnet with route table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security Group for VPC Endpoint
# -----------------------------------------------------------------------------
# This security group controls access to the VPC endpoint:
# - Allows HTTPS (443) from within the VPC only
# - Required because Interface endpoints are ENIs (Elastic Network Interfaces)
# - Gateway endpoints don't need security groups
resource "aws_security_group" "endpoint_sg" {
  name        = "endpoint-sg"
  description = "Security group for S3 VPC endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]  # Only allow access from within VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "endpoint-sg"
  }
}

# Gateway VPC Endpoint for S3
# -----------------------------------------------------------------------------
# Gateway endpoints:
# 1. Are required before creating Interface endpoints with private DNS
# 2. Are free and provide access through AWS backbone network
# 3. Work by adding routes to route tables
# 4. Only support S3 and DynamoDB
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "s3-gateway-endpoint"
  }
}

# Interface VPC Endpoint for S3
# -----------------------------------------------------------------------------
# This creates an ENI in your subnet that:
# 1. Has a private IP address
# 2. Responds to DNS queries for S3
# 3. Handles S3 API requests
# 
# When private_dns_enabled = true:
# - Standard S3 URLs resolve to endpoint's private IP
# - No special configuration needed in applications
# - AWS CLI and SDKs work transparently
resource "aws_vpc_endpoint" "s3_interface" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true  # Makes S3 accessible via standard DNS names

  tags = {
    Name = "s3-interface-endpoint"
  }

  depends_on = [aws_vpc_endpoint.s3_gateway]
}

# Generate random string for bucket name uniqueness
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Demo S3 bucket to test endpoint access
resource "aws_s3_bucket" "demo_bucket" {
bucket        = "demo-endpoint-${random_string.bucket_suffix.result}"
  force_destroy = true 
}



# Sample file in S3 to test access
resource "aws_s3_object" "demo_file" {
  bucket       = aws_s3_bucket.demo_bucket.id
  key          = "hello.txt"
  content      = "Hello from S3 via Interface Endpoint!"
  content_type = "text/plain"
}

# EC2 Instance in private subnet
# -----------------------------------------------------------------------------
# This instance:
# 1. Has NO internet access (private subnet)
# 2. CAN access S3 through VPC endpoint
# 3. Uses standard S3 endpoints (due to private DNS)
# 4. Is completely isolated from internet
resource "aws_instance" "test_instance" {
  ami           = "ami-0c1638aa346a43fe8"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id

  vpc_security_group_ids = [aws_security_group.endpoint_sg.id]

  # The user data script demonstrates endpoint access:
  # - AWS CLI will use the VPC endpoint automatically
  # - No special configuration needed due to private DNS
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y awscli
              # Test S3 access through VPC endpoint
              # This will work despite having no internet access
              aws s3 ls
              EOF

  tags = {
    Name = "endpoint-test-instance"
  }
}

# Output EC2 instance private IP
output "instance_private_ip" {
  value = aws_instance.test_instance.private_ip
}

# Output generated S3 bucket name
output "bucket_name" {
  value = aws_s3_bucket.demo_bucket.id
}