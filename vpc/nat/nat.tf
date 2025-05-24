# Minimal NAT Gateway Example in VPC

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" { region = "ap-northeast-1"}


# Create a VPC
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "example-vpc"
  }
}

# Create a Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Create a Private Subnet
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private-subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-internet-gateway"
  }
}

# Create a NAT Gateway
# A NAT Gateway allows instances in a private subnet to connect to the internet or other AWS services,
# but prevents the internet from initiating connections with those instances.
# Key Parameters:
# - allocation_id: The Elastic IP (EIP) associated with the NAT Gateway, which provides a public IP address.
# - subnet_id: The public subnet where the NAT Gateway is deployed.
# Costs:
# - NAT Gateways incur hourly charges and data processing fees.
# - They are more expensive than VPC endpoints for accessing AWS services.
# Use Cases:
# - Ideal for workloads that require internet access from private subnets, such as downloading updates or accessing external APIs.
# - Not suitable for long-term cost-efficient access to AWS services (use VPC endpoints instead).
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "example-nat-gateway"
  }
}

# Create a Route Table for the Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create a Route Table for the Private Subnet
# The private route table routes internet-bound traffic through the NAT Gateway.
# This ensures that instances in the private subnet can access the internet securely.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Additional Resources for Testing Private Subnet Connectivity
# These resources are NOT required for the NAT Gateway setup.
# They are implemented solely to validate internet connectivity from the private subnet.

# Create an IAM Role for SSM
resource "aws_iam_role" "ssm_role" {
  name = "ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ssm-role"
  }
}

# Attach SSM Managed Policy to the Role
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create an EC2 Instance in the Private Subnet
resource "aws_instance" "private_instance" {
  ami                    = "ami-0c1638aa346a43fe8" # Updated AMI ID
  instance_type          = "t2.micro" # Updated instance type
  subnet_id              = aws_subnet.private.id
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  tags = {
    Name = "private-instance"
  }
}

# Create an Instance Profile for the EC2 Instance
# Instance profiles are used to grant permissions to EC2 instances to interact with AWS services.
# For example, if the NAT Gateway needs to log metrics to CloudWatch or access other AWS resources, an instance profile with the appropriate IAM role is required.

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

# Add an SSM Endpoint to the VPC
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.example.id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "SSM Endpoint"
  }
}

# EC2 Messages endpoint – required for SSM control channel
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.example.id
  service_name        = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "EC2Messages Endpoint"
  }
}

# SSM Messages endpoint – required for Session Manager data channel
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.example.id
  service_name        = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "SSMMessages Endpoint"
  }
}

resource "aws_security_group" "endpoint_sg" {
  name        = "endpoint-sg"
  description = "Allow SSM traffic"
  vpc_id      = aws_vpc.example.id

  ingress {
    description      = "Allow HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.example.cidr_block]
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

# Validation Steps:
# 1. Navigate to the AWS Systems Manager (SSM) console and ensure the instance is listed under managed instances.
# 2. Use the AWS CLI or SSM Session Manager to start a session with the instance.
# 3. Run a curl command to test connectivity, for example:
#    curl http://example.com
#    This will validate that the instance can access the internet through the NAT gateway.
# You should see a response from the website, indicating successful internet access.


## VALIDATE THAT IT WAS INDEED NAT THAT ENABLED INTERNET ACCESS
# 4. Destroy the NAT Gateway using Terraform to validate that it was indeed required for internet access:
#    terraform destroy -target=aws_nat_gateway.example -auto-approve
#
# 5. Try curl again. It should fail, proving that NAT Gateway was enabling internet access.
# >> sh-5.2$ curl --max-time 3 http://example.com
# >> curl: (28) Connection timed out after 3001 milliseconds