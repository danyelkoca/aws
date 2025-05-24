# ----------------------------------------------------------------------------
# Minimal VPC with Flow Logs and Apache Server
# ----------------------------------------------------------------------------

# Provider Configuration
provider "aws" {
  region = "ap-northeast-1"
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-with-flow-logs"
  }
}

# Subnet Configuration
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-internet-gateway"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for HTTP Access
resource "aws_security_group" "http_sg" {
  name        = "http-sg"
  description = "Allow HTTP access to EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "http-sg"
  }
}

# EC2 Instance with Apache HTTP Server
resource "aws_instance" "web_instance" {
  ami                    = "ami-0c1638aa346a43fe8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.http_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo '<html><body><h1>Hello World</h1></body></html>' > /var/www/html/index.html
              EOF

  tags = {
    Name = "web-instance"
  }
}

# IAM Role for Flow Logs
resource "aws_iam_role" "flow_logs_role" {
  name = "vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_logs_policy" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# CloudWatch Log Group for Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  name = "/aws/vpc/flow-logs"

  tags = {
    Name = "vpc-flow-logs"
  }
}

# Enable Flow Logs for the VPC
resource "aws_flow_log" "vpc_flow_logs" {
  log_destination       = aws_cloudwatch_log_group.flow_logs.arn
  iam_role_arn           = aws_iam_role.flow_logs_role.arn
  vpc_id                 = aws_vpc.main.id
  traffic_type           = "ALL"

  tags = {
    Name = "vpc-flow-logs"
  }
}

# ----------------------------------------------------------------------------
# S3 Bucket with CloudWatch Logs
# ----------------------------------------------------------------------------
# This configuration creates an S3 bucket and enables CloudWatch Logs to save
# there. Note: Filtering is optional but recommended to reduce the volume of
# data, as CloudWatch logs a lot of data, making it difficult to interpret
# without filtering.

# Create an S3 bucket to store CloudWatch Logs
resource "aws_s3_bucket" "cloudwatch_logs_bucket" {
  bucket = "cloudwatch-logs-bucket-${random_string.suffix.result}"

  tags = {
    Name = "cloudwatch-logs-bucket"
  }
}

# Generate a random suffix for the bucket name to ensure uniqueness
resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

# Enable CloudWatch Logs to save to the S3 bucket
resource "aws_cloudwatch_log_destination" "s3_destination" {
  name       = "cloudwatch-to-s3"
  target_arn = aws_s3_bucket.cloudwatch_logs_bucket.arn
  role_arn   = aws_iam_role.cloudwatch_logs_role.arn
}

# IAM Role for CloudWatch Logs to write to S3
resource "aws_iam_role" "cloudwatch_logs_role" {
  name = "cloudwatch-logs-to-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "logs.ap-northeast-1.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach a policy to the IAM Role to allow writing to the S3 bucket
resource "aws_iam_role_policy" "cloudwatch_logs_policy" {
  name = "cloudwatch-logs-to-s3-policy"
  role = aws_iam_role.cloudwatch_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.cloudwatch_logs_bucket.arn,
          "${aws_s3_bucket.cloudwatch_logs_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Outputs
output "web_instance_public_ip" {
  value       = aws_instance.web_instance.public_ip
  description = "Public IP address of the Apache EC2 instance"
}

# 0. Example CloudWatch Log Entry and Explanation:
# Example Log: 2 AWS_ACCOUNT_ID ENI_ID YOUR_IP_ADDRESS 10.0.1.61 36005 80 6 7 1408 1748072863 1748072913 ACCEPT OK
# Explanation:
# - "2": Log version.
# - "AWS_ACCOUNT_ID": AWS account ID.
# - "ENI_ID": Elastic Network Interface (ENI) ID.
# - "YOUR_IP_ADDRESS": Source IP address.
# - "10.0.1.61": Destination IP address.
# - "36005": Source port.
# - "80": Destination port (HTTP).
# - "6": Protocol (6 = TCP).
# - "7": Number of packets transferred.
# - "1408": Number of bytes transferred.
# - "1748072863": Start time (UNIX timestamp).
# - "1748072913": End time (UNIX timestamp).
# - "ACCEPT": Action taken (ACCEPT or REJECT).
# - "OK": Log status.

# 1. S3 is not needed for viewing or filtering CloudWatch Logs:
# CloudWatch Logs can be accessed and filtered directly using the AWS Management Console or AWS CLI without requiring S3.

# 2. What happens if S3 is not used:
# If S3 is not used, CloudWatch Logs are retained based on the retention period configured for the log group. After the retention period, logs are automatically deleted. S3 can be used for long-term storage and archival of logs.

# 3. Accessing and Filtering CloudWatch Logs with AWS CLI:
# Example Command:
# aws logs filter-log-events \
#   --log-group-name "/aws/vpc/flow-logs" \
#   --filter-pattern '[version, accountid, interfaceid, srcaddr = YOUR_IP_ADDRESS, dstaddr, srcport, dstport = 80, protocol, packets, bytes, start, end, action = ACCEPT, logstatus]' \
#   --region ap-northeast-1
# This command filters logs for TCP traffic (protocol 6), source IP YOUR_IP_ADDRESS, destination port 80, and action ACCEPT.

