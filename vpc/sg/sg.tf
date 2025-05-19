# -----------------------------------------------------------------------------
# NOTE ON SSH KEY USAGE
# -----------------------------------------------------------------------------
# We created an EC2 key pair named "<your-key>" previously for another EC2 instance.
# Terraform refers to it using key_name = "<your-key>" even if the .pem file is not 
# within the Terraform directory. As long as AWS has the key registered, EC2 
# instances will accept it for SSH.
#
# If you haven't created this key pair yet, run the following commands:
#
#   aws ec2 create-key-pair --key-name <your-key> --query 'KeyMaterial' --output text > <your-key>.pem
#   chmod 400 <your-key>.pem
#
# This will allow you to SSH into the EC2 instance using. Make sure to change the path og <your-key>.pem
#   ssh -i <your-key>.pem ec2-user@<public-ip>


# -----------------------------------------------------------------------------
# AWS Security Group Configuration
# -----------------------------------------------------------------------------
# Security Groups (SGs) act as virtual firewalls for controlling inbound and 
# outbound traffic to AWS resources, most commonly EC2 instances.
#
# - SGs are **stateful**: return traffic is automatically allowed.
# - SGs must always be associated with a VPC.
# - This example allows:
#     * SSH access (port 22) from a specific IP.
#     * HTTP access (port 80) from anywhere.
#     * All outbound traffic.
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Security Groups vs. Network ACLs (NACLs)
# -----------------------------------------------------------------------------
# Security Groups (SGs):
#   - Operate at the instance level (attached to EC2 instances).
#   - Are stateful: return traffic is automatically allowed.
#   - Default behavior: deny all inbound traffic, allow all outbound traffic.
#   - Evaluate all rules together; if no rule matches, traffic is denied.
#
# Network ACLs (NACLs):
#   - Operate at the subnet level (attached to subnets).
#   - Are stateless: return traffic must be explicitly allowed.
#   - Default behavior: allow nothing unless explicitly allowed.
#   - Evaluate rules in numbered order; first match wins (allow or deny).
#
# SGs are generally easier to manage for EC2 security. NACLs provide broader
# control across entire subnets and can be used to implement additional layers
# of network security.
# -----------------------------------------------------------------------------

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

# -----------------------------------------------------------------------------
# Create a Subnet in the VPC
# -----------------------------------------------------------------------------
resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "main-subnet"
  }
}

# -----------------------------------------------------------------------------
# Create an Internet Gateway and attach to VPC
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "main-igw"
  }
}

# -----------------------------------------------------------------------------
# Create a Route Table and associate with Subnet
# -----------------------------------------------------------------------------
resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "main-rt"
  }
}

resource "aws_route_table_association" "main_rt_assoc" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_rt.id
}

# -----------------------------------------------------------------------------
# Create a Security Group within the VPC
# -----------------------------------------------------------------------------
resource "aws_security_group" "main_sg" {
  name        = "main-sg"
  description = "Allow HTTP and SSH access"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<your-ip-address>/32"] # User's IPv4 address only
  }

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
    Name = "main-sg"
  }
}

# -----------------------------------------------------------------------------
# Create an EC2 instance and assign Security Group
# -----------------------------------------------------------------------------
resource "aws_instance" "main_instance" {
  ami                    = "ami-0c1638aa346a43fe8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.main_sg.id]
  key_name               = "<your-key>"

  # Use cloud-init to install nginx (Amazon Linux 2023 requires dnf)
  user_data = <<-EOF
              #!/bin/bash
              # Update packages
              dnf update -y

              # Install nginx
              dnf install -y nginx

              # Enable and start nginx service
              systemctl enable nginx
              systemctl start nginx

              # Create a simple static HTML page (First test)
              # echo "<html><body><h1>Hello from EC2 with SG</h1></body></html>" > /usr/share/nginx/html/index.html

              # Upload a file directly from local (Second test)
              echo '${file("${path.module}/index.html")}' > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "main-instance"
  }
}

# -----------------------------------------------------------------------------
# Access Notes:
# -----------------------------------------------------------------------------
# - HTTP (port 80) is publicly accessible.
# - SSH (port 22) access is restricted to your IPv4 address.
# - To connect via SSH:
#     ssh -i <your-key>.pem ec2-user@<public-ip>
#   Replace <public-ip> with the instance's public IP.
# -----------------------------------------------------------------------------


 # -----------------------------------------------------------------------------
 # Output: Public HTTP URL
 # -----------------------------------------------------------------------------
 # Note: This EC2 instance does not have TLS/SSL configured.
 # Browsers attempting to connect via https:// will fail with connection errors.
 # Always use http:// when testing unless you've explicitly configured HTTPS.
output "main_ec2_public_url" {
  value       = "http://${aws_instance.main_instance.public_ip}"
  description = "URL to test HTTP access to the EC2 instance"
}

# -----------------------------------------------------------------------------
# Output: SSH command to connect to the EC2 instance
# -----------------------------------------------------------------------------
output "main_ec2_ssh_command" {
  value       = "ssh -i <your-key>.pem ec2-user@${aws_instance.main_instance.public_ip}"
  description = "SSH command to connect to the EC2 instance"
}
