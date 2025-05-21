# Create VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

# Create public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public-subnet"
  }
}

# Create and attach internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  
  tags = {
    Name = "main-igw"
  }
}

# Create route table with route to internet gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Create security group
resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "Allow HTTP access"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow HTTP from anywhere
  ingress {
    description = "HTTP access"
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
    Name = "instance-sg"
  }
}

resource "aws_instance" "web_instance" {
  ami                    = "ami-0c1638aa346a43fe8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              # Install Apache HTTP Server (httpd)
              dnf install -y httpd
              
              # Start the httpd service immediately
              systemctl start httpd
              
              # Enable httpd to start on boot
              systemctl enable httpd
              
              # Create a simple test page in the default web root
              echo '<html><body><h1>Hello World</h1></body></html>' > /var/www/html/index.html
              EOF

  tags = {
    Name = "web-instance"
  }
}

# -----------------------------------------------------------------------------
# What is an Elastic IP (EIP)?
# -----------------------------------------------------------------------------
# An Elastic IP address is a static, public IPv4 address that you can allocate 
# to your AWS account. Key features and uses:
#
# 1. Static Public IP:
#    - Unlike auto-assigned public IPs that change when instance restarts
#    - Remains constant even if the instance is stopped/started
#    - Useful for applications that require a fixed IP address
#
# 2. Common Use Cases:
#    - Hosting domains/DNS records that point to your instance
#    - Whitelisting IP for external services/firewalls
#    - Running services that other applications depend on
#    - Failover scenarios where IP needs to be moved between instances
#
# 3. Key Benefits:
#    - Masks instance/availability zone failures by remapping the IP
#    - Can be quickly remapped from one instance to another
#    - Helps maintain stable endpoints for your applications
#
# 4. Limitations:
#    - Limited to 5 EIPs per region by default (can be increased)
#    - Only works with IPv4 (not IPv6)
#    - Must be in the same region as the instance
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Elastic IP Cost Information:
# -----------------------------------------------------------------------------
# 1. Elastic IP is FREE when:
#    - It is associated with a running EC2 instance
#    - You have only one EIP per running instance
#
# 2. Elastic IP COSTS money when:
#    - It is NOT associated with a running instance ($0.005/hour or ~$3.6/month)
#    - You have additional EIPs on the same running instance ($0.005/hour)
#    - Your instance is stopped but the EIP is still allocated
#
# Best Practices to Avoid Charges:
# - Always associate EIPs with running instances
# - Release EIPs when instances are terminated
# - Use only one EIP per instance unless absolutely necessary
# - Consider using DNS names for instances that don't need static IPs
# -----------------------------------------------------------------------------

# Create Elastic IP
resource "aws_eip" "web_eip" {
  domain = "vpc" # Specifies that the EIP is for use in a VPC.
  tags = {
    Name = "web-eip" # Tag to identify the Elastic IP resource.
  }
}

# Associate Elastic IP with EC2 instance
# This resource associates the Elastic IP with the EC2 instance, ensuring the instance has a static public IP address.
resource "aws_eip_association" "web_eip_assoc" {
  instance_id   = aws_instance.web_instance.id # The ID of the EC2 instance to associate with the EIP.
  allocation_id = aws_eip.web_eip.id           # The allocation ID of the Elastic IP to associate.
}

# Output public IP for HTTP access
output "website_url" {
  value = "http://${aws_eip.web_eip.public_ip}"
}
