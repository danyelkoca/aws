# -----------------------------------------------------------------------------
# VPC with Gateway Endpoint for S3 Access
# -----------------------------------------------------------------------------
# Gateway Endpoints vs Interface Endpoints:
#
# Gateway Endpoints:
# + Free
# + For S3 and DynamoDB only
# + Uses AWS routing
# - VPC-only access
#
# Interface Endpoints:
# + Works with most AWS services
# + Accessible from on-prem
# + Works across VPC peering
# - Costs money
# - Needs ENIs and security groups

provider "aws" {
  region = "ap-northeast-1"
}

# VPC with DNS support enabled
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "endpoint-vpc"
  }
}

# Private subnet - No internet access needed
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "private-subnet"
  }
}

# Private Route Table - Will get S3 routes automatically
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

# Security Group for EC2 instance
resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance-sg"
  }
}

# -----------------------------------------------------------------------------
# S3 Gateway Endpoint Configuration
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "s3-gateway-endpoint"
  }
}

# Create security group for VPC endpoints
resource "aws_security_group" "vpce_sg" {
  name        = "vpce-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.instance_sg.id]
  }

  tags = {
    Name = "vpce-sg"
  }
}

# Generate random string for bucket name
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
  content      = "Hello from S3 via Gateway Endpoint!"
  content_type = "text/plain"
}

# -----------------------------------------------------------------------------
# SSM Configuration (Only for accessing private instance)
# Not required for S3 Gateway Endpoint functionality
# Alternatives: Public subnet + IGW, Bastion host, NAT Gateway
#
# Components:
# - IAM role & profile: Allows EC2 to use SSM
# - VPC Endpoints (Interface type):
#   * ssm: Main service endpoint
#   * ec2messages: For SSM communication
#   * ssmmessages: For terminal sessions
# -----------------------------------------------------------------------------

# IAM role for SSM and S3 access
resource "aws_iam_role" "ssm_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach SSM policy
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Add S3 permissions
resource "aws_iam_role_policy" "s3_policy" {
  name = "s3-policy"
  role = aws_iam_role.ssm_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::*",  # For ListAllMyBuckets
          "arn:aws:s3:::${aws_s3_bucket.demo_bucket.id}",
          "arn:aws:s3:::${aws_s3_bucket.demo_bucket.id}/*"
        ]
      }
    ]
  })
}

# Create instance profile
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

# VPC Endpoints for Systems Manager
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "ssm-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "ssmmessages-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "ec2messages-endpoint"
  }
}

# EC2 Instance in private subnet
resource "aws_instance" "test_instance" {
  ami                    = "ami-0c1638aa346a43fe8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  iam_instance_profile  = aws_iam_instance_profile.ssm_instance_profile.name
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y awscli
              # SSM Agent is pre-installed on Amazon Linux 2023
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              # Test S3 access through Gateway endpoint
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
