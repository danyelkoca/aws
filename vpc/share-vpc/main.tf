# AWS provider configuration
provider "aws" {
  region = "ap-northeast-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  # Optional: Tag for easier identification in AWS Console
  tags = {
    Name = "MainVPC"
  }
}

# Subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  # Optional: Tag for easier identification in AWS Console
  tags = {
    Name = "MainSubnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  # Optional: Tag for easier identification in AWS Console
  tags = {
    Name = "MainIGW"
  }
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  # Optional: Tag for easier identification in AWS Console
  tags = {
    Name = "MainRouteTable"
  }
}

# Default Route
resource "aws_route" "default" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Route Table Association
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# RAM Share with another AWS account
# NOTE: Make sure organization sharing is enabled in RAM settings of the management account.

resource "aws_ram_resource_share" "vpc_share" {
  name                      = "ShareVPC"
  allow_external_principals = false
}

# Associate the principal (target AWS account) with the resource share
resource "aws_ram_principal_association" "principal" {
  principal          = "<ACCOUNT_ID>" # Replace with target AWS account ID
  resource_share_arn = aws_ram_resource_share.vpc_share.arn
}

# Only subnets (not VPCs) can be shared directly
resource "aws_ram_resource_association" "subnet_association" {
  resource_arn       = aws_subnet.main.arn
  resource_share_arn = aws_ram_resource_share.vpc_share.arn
}

# --------------------------------------------------
# EC2 Sharing Notes
# --------------------------------------------------
# - EC2 instances themselves cannot be shared across accounts.
# - The shared subnet allows the grantee to launch, list, and manage their own EC2 instances.
# - EC2 instances created in the granter account are not visible or accessible in the grantee account.
# - To allow cross-account EC2 access:
#   - Use IAM role assumption with a trust policy
#   - Share SSH credentials
#   - Use Systems Manager Session Manager if configured
# --------------------------------------------------

# Security Group for EC2 Instance
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance in shared subnet
resource "aws_instance" "example" {
  ami                    = "ami-0c1638aa346a43fe8" # Amazon Linux 2023 in ap-northeast-1
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "SharedSubnetInstance"
  }
}
