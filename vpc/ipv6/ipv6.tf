# -----------------------------------------------------------------------------
# IPv6 VPC Configuration
# -----------------------------------------------------------------------------
# Enable IPv6 in VPC for:
# - Global uniqueness: Every IPv6 address is globally unique
# - Future-proof: IPv6 has vastly larger address space than IPv4 (2^128 vs 2^32)
# - Modern applications: Better support for modern cloud-native apps
# - No NAT needed: Every IPv6 address is publicly routable
# 
# IPv6 CIDR Blocks in AWS:
# - VPC gets a /56 prefix length (allows for 256 /64 subnets)
# - Each subnet gets a /64 prefix length (plenty of IPs per subnet)
# - AWS auto-generates these CIDRs from Amazon's IPv6 address pool
# -----------------------------------------------------------------------------

# Create VPC with IPv6 support
resource "aws_vpc" "main_vpc" {
  cidr_block                       = "10.0.0.0/16"  # IPv4 CIDR (still needed for legacy support)
  assign_generated_ipv6_cidr_block = true          # Requests AWS to assign a /56 IPv6 CIDR block
  
  # DNS Settings for IPv6:
  # ---------------------
  # 1. enable_dns_support = true
  #    - Enables DNS resolution through Amazon's DNS server (169.254.169.253)
  #    - While not specifically required for IPv6, it's recommended when using dual-stack
  #    - Helps instances resolve both IPv4 and IPv6 DNS records if available
  #
  # 2. enable_dns_hostnames = true
  #    - Auto-assigns DNS hostnames to instances in the VPC
  #    - Required for IPv6: Enables instances to get AAAA DNS records
  #    - Necessary for proper IPv6 DNS resolution and reverse DNS lookup
  #    - Without this, instances won't get IPv6 DNS hostnames
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# Create public subnet with IPv6 support
resource "aws_subnet" "public_subnet" {
  vpc_id                          = aws_vpc.main_vpc.id
  cidr_block                      = "10.0.1.0/24"  # IPv4 CIDR
  availability_zone               = "ap-northeast-1a"

  # IPv6 Subnet Configuration:
  # ------------------------
  # 1. assign_ipv6_address_on_creation = true
  #    - Automatically assigns IPv6 addresses to instances launched in this subnet
  #    - Similar to map_public_ip_on_launch but for IPv6
  #    - Ensures instances are IPv6-capable by default
  #
  # 2. ipv6_cidr_block = cidrsubnet(...)
  #    - Calculates a /64 subnet from the VPC's /56 IPv6 CIDR
  #    - cidrsubnet function parameters:
  #      * aws_vpc.main_vpc.ipv6_cidr_block: The VPC's /56 IPv6 CIDR
  #      * 8: Number of bits to extend the prefix (56 + 8 = 64)
  #      * 1: Subnet number (can be 0-255, as we have 8 bits = 256 subnets)
  
  # Auto-assign IPs
  map_public_ip_on_launch         = true  # Auto-assign IPv4
  assign_ipv6_address_on_creation = true  # Auto-assign IPv6
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main_vpc.ipv6_cidr_block, 8, 1)

  tags = {
    Name = "public-subnet"
  }
}

# Create and attach internet gateway (supports both IPv4 and IPv6)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  
  tags = {
    Name = "main-igw"
  }
}

# Create route table with routes for both IPv4 and IPv6
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  # IPv4 default route (legacy support)
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  # IPv6 default route
  # -----------------
  # - ::/0 represents all IPv6 addresses (similar to 0.0.0.0/0 in IPv4)
  # - Required for outbound internet access over IPv6
  # - The same IGW handles both IPv4 and IPv6 traffic
  # - No NAT gateway needed for IPv6 as all addresses are public
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
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

# Create security group with IPv6 support
resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "Allow HTTP access via IPv4 and IPv6"
  vpc_id      = aws_vpc.main_vpc.id

  # IPv6 Security Group Rules:
  # ------------------------
  # 1. Ingress rules need both IPv4 and IPv6 variants
  #    - IPv4 uses cidr_blocks
  #    - IPv6 uses ipv6_cidr_blocks
  #    - ::/0 allows access from any IPv6 address
  #
  # 2. Egress rules also need both variants
  #    - Enables instances to communicate with both IPv4 and IPv6 endpoints
  #    - Essential for software updates, external services, etc.

  # Allow HTTP from anywhere (IPv4)
  ingress {
    description = "HTTP access IPv4"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP from anywhere (IPv6)
  ingress {
    description      = "HTTP access IPv6"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  # Allow all outbound traffic (IPv4)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic (IPv6)
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "instance-sg"
  }
}

# Create EC2 instance with IPv6 support
resource "aws_instance" "web_instance" {
  ami                    = "ami-0c1638aa346a43fe8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  # IPv6 Instance Configuration:
  # --------------------------
  # ipv6_address_count = 1
  # - Requests one IPv6 address for the instance
  # - Unlike IPv4, no need to choose between public/private addresses
  # - All IPv6 addresses are globally unique and internet-routable
  # - Instance will get both IPv4 and IPv6 addresses
  ipv6_address_count = 1

  user_data = <<-EOF
              #!/bin/bash
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo '<html><body><h1>Hello World from IPv6!</h1></body></html>' > /var/www/html/index.html
              EOF

  tags = {
    Name = "web-instance"
  }
}

# Output both IPv4 and IPv6 addresses
output "website_url_ipv4" {
  value = "http://${aws_instance.web_instance.public_ip}"
}

# Note: IPv6 addresses in URLs must be enclosed in square brackets
output "website_url_ipv6" {
  value = "http://[${aws_instance.web_instance.ipv6_addresses[0]}]"
}