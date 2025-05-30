provider "aws" {
  region = "ap-northeast-1"
}

######################
# Data Sources      #
######################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

######################
# VPC Setup         #
######################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "alb-vpc"
  }
}

# Private Subnets (for EC2 instances)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "private-subnet-2"
  }
}



# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "private-rt"
  }
}

# Private Route Table Associations
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

######################
# EC2 Instances     #
######################

# EC2 Instance in AZ1
resource "aws_instance" "web_1" {
  ami           = data.aws_ami.amazon_linux.id # Latest Amazon Linux 2023
  instance_type = "t2.micro"

  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              instanceId=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
              az=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
              cat << INNEREOF > /usr/share/nginx/html/index.html
              <!DOCTYPE html>
              <html>
              <body style="background-color: lightblue;">
                  <h1>Hello from BLUE Server</h1>
                  <p>This is server 1 in ap-northeast-1a</p>
              </body>
              </html>
              INNEREOF
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "web-server-1"
  }
}

# EC2 Instance in AZ2
resource "aws_instance" "web_2" {
  ami           = data.aws_ami.amazon_linux.id # Latest Amazon Linux 2023
  instance_type = "t2.micro"

  subnet_id              = aws_subnet.private_2.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              instanceId=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
              az=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
              cat << INNEREOF > /usr/share/nginx/html/index.html
              <!DOCTYPE html>
              <html>
              <body style="background-color: lightgreen;">
                  <h1>Hello from GREEN Server</h1>
                  <p>This is server 2 in ap-northeast-1c</p>
              </body>
              </html>
              INNEREOF
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "web-server-2"
  }
}

######################
# NAT Gateway       #
######################

# EIP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name = "nat-eip"
  }
}

# NAT Gateway in first public subnet (from alb.tf)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id  # Using existing public subnet from alb.tf

  tags = {
    Name = "main-nat-gateway"
  }
}

######################
# Outputs           #
######################

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = "http://${aws_lb.web.dns_name}"
}

output "instance_ids" {
  description = "Instance IDs for SSM access"
  value = {
    web1 = aws_instance.web_1.id
    web2 = aws_instance.web_2.id
  }
}
