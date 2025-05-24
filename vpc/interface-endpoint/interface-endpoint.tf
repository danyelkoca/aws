# -----------------------------------------------------------------------------
# VPC with Interface Endpoint
# -----------------------------------------------------------------------------
# Interface Endpoints allow private access to AWS services without Internet
# 
# Costs:
# - $0.01 per endpoint per AZ per hour
# - Data processing charges per GB
#
# Most commonly used with:
# 1. Systems Manager (SSM) Suite:
#    - ssm: Main service endpoint
#    - ssmmessages: Session Manager
#    - ec2messages: SSM communication
#
# 2. Container Services:
#    - ecr.api: Container Registry API
#    - ecr.dkr: Docker Registry
#    - ecs: Container Service
#
# 3. Security Services:
#    - secrets manager: Store secrets
#    - kms: Key Management
#    - sts: Security Token Service
#
# 4. Monitoring:
#    - logs: CloudWatch Logs
#    - monitoring: CloudWatch Metrics
#
# Interface vs Gateway Endpoints:
# Interface:                    | Gateway:
# - Works with most services   | - Only S3 and DynamoDB
# - Costs money               | - Free
# - Uses ENIs                 | - Uses route tables
# - Works across VPC peering  | - VPC-only
# - Needs security groups     | - No security groups needed
# - Multiple AZ support       | - Highly available by default



## THIS PARTICULAR EXAMPLE IS FOR SECRETS MANAGER
# -----------------------------------------------------------------------------
# Minimal VPC with Interface Endpoint for Secrets Manager
# -----------------------------------------------------------------------------
provider "aws" {
  region = "ap-northeast-1"
}

# VPC with DNS support (required for endpoints)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
}

# Route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security group
resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.main.id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443        # Allow HTTPS to the endpoint ENI
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]  # Only traffic from inside VPC
  }
}

# Secrets Manager endpoint
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.sg.id]
  private_dns_enabled = true
}

# IAM role
resource "aws_iam_role" "role" {
  name = "test-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Simple policy with extended permissions for Secrets Manager
resource "aws_iam_policy" "policy" {
  name = "test-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:TagResource"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_instance_profile" "profile" {
  name = "test-profile"
  role = aws_iam_role.role.name
}

# EC2 Instance
resource "aws_instance" "instance" {
  ami                    = "ami-0c1638aa346a43fe8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  iam_instance_profile   = aws_iam_instance_profile.profile.name
  vpc_security_group_ids = [aws_security_group.sg.id]

  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /dev/console) 2>&1  # Force output to serial console
              set -x  # Enable command tracing

              echo "Installing AWS CLI"
              dnf install -y awscli

              export AWS_REGION="ap-northeast-1"  # Ensure CLI uses correct region

              echo "Creating Secrets Manager secret..."
              aws secretsmanager create-secret \
                --name "endpoint-validation-secret" \
                --secret-string "Created from private instance via VPC endpoint"

              echo "Secret creation complete"
              EOF
}