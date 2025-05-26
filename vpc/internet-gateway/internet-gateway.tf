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
  description = "Allow HTTP and SSH access"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow HTTP from anywhere
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH only from your IP
  ingress {
    description = "SSH access from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["153.240.32.13/32"]
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

# -----------------------------------------------------------------------------
# Web Server Choice: Apache HTTP Server (httpd) vs NGINX
# -----------------------------------------------------------------------------
# We're using httpd (Apache) here instead of NGINX because:
#
# 1. Simplicity for Static Content:
#    - httpd is ideal for serving basic static HTML files
#    - Default configuration works out of the box
#    - No complex configuration needed for our simple use case
#
# 2. Amazon Linux 2023 Integration:
#    - httpd is well-tested and optimized for Amazon Linux
#    - Seamless integration with systemd service management
#    - Maintained and updated through dnf package manager
#
# 3. Resource Usage:
#    - For simple static pages, httpd's resource usage is minimal
#    - We don't need NGINX's advanced features like:
#      * Load balancing
#      * Reverse proxying
#      * Complex URL routing
#      * Advanced caching
#
# 4. Use Case Appropriateness:
#    - NGINX would be preferred for:
#      * High-concurrency scenarios
#      * Microservices architecture
#      * Reverse proxy needs
#      * Load balancing multiple backends
#    - httpd is perfect for:
#      * Simple static file serving
#      * Basic web hosting
#      * Small to medium traffic sites
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# SSH Key Compatibility Notes:
# -----------------------------------------------------------------------------
# Different AMIs use different default users for SSH access:
# - Amazon Linux 2023 (this AMI): ec2-user
# - Ubuntu: ubuntu
# - RHEL: ec2-user
# - SUSE: ec2-user
# - Debian: admin
# 
# If your SSH key doesn't work:
# 1. Verify you're using the correct default user for the AMI
# 2. Ensure the key pair is in the same region as the instance
# 3. Check the key permissions are set to 400 (chmod 400 key.pem)
# -----------------------------------------------------------------------------

resource "aws_instance" "web_instance" {
  ami                    = "ami-0c1638aa346a43fe8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  key_name              = "MainKey"  # Using existing key pair that was created and saved to path/to/keypair/pem/file

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

# Output public IP for HTTP access
output "website_url" {
  value = "http://${aws_instance.web_instance.public_ip}"
}

# Output SSH command
output "ssh_command" {
  value = "ssh -i  path/to/keypair/pem/file ec2-user@${aws_instance.web_instance.public_ip}"
}
