##############################################################################
# -----------------------------------------------------------------------------
# IMPORTANT: Prerequisite - Generate EC2 SSH Key Pair
# -----------------------------------------------------------------------------
# Before applying this Terraform configuration, you must create an EC2 key pair.
# This is required for SSH access to the EC2 instance.
#
# Run the following command to create the key and save it locally:
#
#   aws ec2 create-key-pair \
#     --key-name <your-key> \
#     --query 'KeyMaterial' \
#     --output text > <your-key>.pem
#
# Then secure the key:
#
#   chmod 400 <your-key>.pem
#
# Terraform will reference this key by name ("<your-key>") when launching the EC2 instance.
# -----------------------------------------------------------------------------
##############################################################################

provider "aws" {
  region = "ap-northeast-1"
}

# -----------------------------------------------------------------------------
# VPC: Defines the network boundary for all resources in this environment.
# CIDR block "10.0.0.0/16" provides a large private address space.
# This forms the outer boundary of your network.
# All subnets, NACLs, and EC2 instances are created within this VPC.
# -----------------------------------------------------------------------------
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16" # "10.0.0.0/16" is a private CIDR block giving up to 65,536 IP addresses.

  tags = {
    Name = "Main-VPC"
  }
}

# -----------------------------------------------------------------------------
# Subnet: A segment of the VPC's IP range in a single Availability Zone.
# CIDR block "10.0.1.0/24" is a subset of the VPC's CIDR block.
# Each subnet must reside in a single AZ and be unique within the VPC.
# Public subnet: needs to have a route to an IGW AND instances with public IPs.
# Configured to auto-assign public IPs so instances are internet reachable.
# -----------------------------------------------------------------------------
resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24" # "10.0.1.0/24" is a subnet of the above block, giving 256 IPs for one AZ.
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true # Ensures instances launched here get public IPs

  tags = {
    Name = "Main-Subnet"
  }
}

# -----------------------------------------------------------------------------
# Internet Gateway: Allows resources in the VPC to connect to the internet.
# Alone, the IGW provides no access unless the route table directs traffic to it.
# Required for any public internet access.
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Main-IGW"
  }
}

# -----------------------------------------------------------------------------
# Route Table: Directs subnet traffic to the Internet Gateway for internet access.
# The route "0.0.0.0/0" → IGW means send all non-local traffic to the internet.
# Required for public subnets.
# Contains a route for all outbound (0.0.0.0/0) traffic via IGW.
# -----------------------------------------------------------------------------
resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # "0.0.0.0/0" means all IPv4 addresses everywhere (i.e., the entire internet).
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "Main-RouteTable"
  }
}

# -----------------------------------------------------------------------------
# Route Table Association: Connects the subnet to the route table so it can reach
# the internet via the IGW.
# -----------------------------------------------------------------------------
resource "aws_route_table_association" "main_rt_assoc" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_rt.id
}

# -----------------------------------------------------------------------------
# Network ACL: Stateless firewall at the subnet level.
# NACLs are stateless: each direction must be explicitly allowed.
# Unlike SGs, they apply to all traffic in/out of the subnet.
# Only one NACL per subnet. This replaces the default NACL.
# Custom NACL for the subnet, initially with no rules (rules added separately).
# -----------------------------------------------------------------------------
resource "aws_network_acl" "main_acl" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Main-ACL"
  }
}

# -----------------------------------------------------------------------------
# NACL Rule: Explicitly DENY traffic from specific IP for testing
# This rule denies all incoming traffic from the user's IP address
# to verify that the NACL blocks traffic as expected.
# Rule number 90 is evaluated before the allow rule at 100.
# -----------------------------------------------------------------------------
# Result:
# Any requests from IP <test-ip> will be blocked by this rule.
# This means:
# - The request will not reach the EC2 instance.
# - The browser will show a timeout or unreachable error.
# - Other IPs not explicitly denied will still be able to access normally.
# This confirms that the NACL is functioning correctly and evaluated before SG.
# -----------------------------------------------------------------------------
resource "aws_network_acl_rule" "main_deny_ingress_my_ip" {
  network_acl_id = aws_network_acl.main_acl.id
  rule_number    = 90
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "<test-ip>/32" # Blocks this specific IPv4 address.
  # Set this to your IP to test the deny rule.
  # Currently we set a placeholder IP.
}

# -----------------------------------------------------------------------------
# NACL Rule: Allow all inbound traffic (ingress) to the subnet.
# Protocol "-1" means all protocols, rule number 100 for high precedence.
# -----------------------------------------------------------------------------
resource "aws_network_acl_rule" "main_allow_ingress_all" {
  network_acl_id = aws_network_acl.main_acl.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0" # "0.0.0.0/0" means all IPv4 addresses everywhere (i.e., the entire internet).
}

# -----------------------------------------------------------------------------
# NACL Rule: Allow all outbound traffic (egress) from the subnet.
# Protocol "-1" means all protocols, rule number 100 for high precedence.
# -----------------------------------------------------------------------------
resource "aws_network_acl_rule" "main_allow_egress_all" {
  network_acl_id = aws_network_acl.main_acl.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0" # "0.0.0.0/0" means all IPv4 addresses everywhere (i.e., the entire internet).
}

# -----------------------------------------------------------------------------
# NACL Association: Associates the custom NACL with the subnet.
# Only one NACL can be associated per subnet at a time.
# -----------------------------------------------------------------------------
resource "aws_network_acl_association" "main_acl_assoc" {
  subnet_id      = aws_subnet.main_subnet.id
  network_acl_id = aws_network_acl.main_acl.id
}

# -----------------------------------------------------------------------------
# Security Group: Stateful firewall at the instance level.
# SGs are stateful: allowing ingress means egress response is implicitly allowed.
# Acts as a firewall for the instance itself.
# Attached to the EC2 instance for secure access.
# -----------------------------------------------------------------------------
resource "aws_security_group" "main_sg" {
  name        = "Main-SG"
  description = "Security group allowing HTTP and SSH access"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow HTTP (port 80) access from any IP address
  ingress {
    from_port   = 80            # Start of port range
    to_port     = 80            # End of port range
    protocol    = "tcp"         # TCP protocol
    cidr_blocks = ["0.0.0.0/0"] # Allow from all IPv4 addresses
  }

  # Allow SSH (port 22) access only from your current public IP.
  # This enables secure remote access to the EC2 instance via your IDE or terminal.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<your-ip>/32"]
    # This rule allows SSH access from your IDE's public IP only
    # Set this to your current public IP.
  }

  # Allow all outbound traffic from the instance
  egress {
    from_port   = 0             # Start of port range
    to_port     = 0             # End of port range
    protocol    = "-1"          # All protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow to all IPv4 addresses
  }

  tags = {
    Name = "Main-SG"
  }
}

# -----------------------------------------------------------------------------
# EC2 Instance: Virtual machine launched in the public subnet.
# This EC2 is placed in the public subnet and assigned a public IP.
# This, plus SG + NACL + IGW + Route Table, enables HTTP (web) access.
# Uses the security group for SSH access and inherits NACL rules from the subnet.
# -----------------------------------------------------------------------------
resource "aws_instance" "main_instance" {
  # AMI: Amazon Linux 2023 (uses dnf instead of yum)
  ami                    = "ami-0c1638aa346a43fe8"         # Amazon Linux 2023 AMI ID for ap-northeast-1
  instance_type          = "t2.micro"                      # Instance type eligible for free tier
  subnet_id              = aws_subnet.main_subnet.id       # Launch in our public subnet
  vpc_security_group_ids = [aws_security_group.main_sg.id] # Apply our security group
  key_name               = "<your-key>"                       # Use the pre-existing EC2 key pair for SSH access

  user_data = <<-EOF
             #!/bin/bash
              # Update packages
              dnf update -y

              # Install nginx
              dnf install -y nginx

              # Enable and start nginx service
              systemctl enable nginx
              systemctl start nginx
              EOF

  tags = {
    Name = "Main-Instance" # Name tag for the instance
  }
}

# -----------------------------------------------------------------------------
# Access Notes:
# -----------------------------------------------------------------------------
# - HTTP (port 80) is publicly accessible.
#   You do not need SSH access to verify it; just open the public URL in your browser.
#
# - SSH (port 22) access is configured.
#   You can connect to the EC2 instance securely from your machine:
#     1. Ensure you have the EC2 private key file named '<your-key>.pem'.
#     2. From your terminal or IDE, run:
#        ssh -i <your-key>.pem ec2-user@<public-ip>
#     3. Replace <public-ip> with the URL shown in the Terraform output.
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# Verification Instructions
# -----------------------------------------------------------------------------
# Once the infrastructure is applied:
# 1. Terraform will output the public URL of the EC2 instance.
# 2. Open the printed URL (http://<public-ip>) in a browser.
# 3. If successful, you will see the Nginx welcome page.
#    This confirms:
#    - EC2 instance is running.
#    - Instance has a public IP.
#    - Subnet routing to IGW works.
#    - Security Group allows HTTP (port 80).
#    - NACL allows inbound/outbound internet traffic.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# SSH Access Instructions
# -----------------------------------------------------------------------------
# To generate the SSH key for accessing this EC2 instance:
#
# Step 1: Generate the key pair via AWS CLI
#   aws ec2 create-key-pair \
#     --key-name <your-key> \
#     --query 'KeyMaterial' \
#     --output text > <your-key>.pem
#
# Step 2: Restrict permissions on the key file
#   chmod 400 <your-key>.pem
#
# Step 3: Connect to the EC2 instance via SSH
#   ssh -i <your-key>.pem ec2-user@<public-ip>
#   (Replace <public-ip> with the IP from Terraform output)
#
# This setup assumes the key pair was created separately and registered with AWS.
# -----------------------------------------------------------------------------
