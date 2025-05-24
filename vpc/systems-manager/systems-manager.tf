# ----------------------------------------------------------------------------
# Minimal VPC with Private Subnet and Systems Manager Interface Endpoint
# ----------------------------------------------------------------------------

provider "aws" {
  region = "ap-northeast-1"
}

# VPC with DNS support (required for endpoints)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "minimal-vpc"
  }
}

# Private subnet - No internet access
# This subnet does not have a route to an Internet Gateway (IGW) or NAT Gateway.
# Instances in this subnet can only access resources within the VPC or through VPC endpoints.
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "private-subnet"
  }
}

# Private Route Table - No routes to the internet
# This route table only contains local VPC routes and routes to VPC endpoints.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security group for VPC endpoints
# This security group is used to control traffic to and from the VPC endpoints.

# This security group is designed to facilitate secure communication between EC2 instances 
# and AWS Systems Manager via VPC endpoints. It ensures that HTTPS traffic (port 443) 
# is allowed within the VPC for secure communication while restricting access to resources 
# outside the VPC. The ingress rule allows EC2 instances to communicate with the Systems 
# Manager VPC endpoint securely over HTTPS. The egress rule permits outbound traffic to 
# any destination, enabling the VPC endpoint to communicate with AWS Systems Manager services.

resource "aws_security_group" "endpoint_sg" {
  name        = "endpoint-sg"  # Name of the security group for identification
  vpc_id      = aws_vpc.main.id  # Associates the security group with the main VPC

  # Ingress rule to allow HTTPS traffic within the VPC
  ingress {
    from_port   = 443  # Allow HTTPS traffic (port 443) for secure communication
    to_port     = 443  # Same as from_port, allowing only HTTPS traffic
    protocol    = "tcp"  # HTTPS uses TCP protocol
    cidr_blocks = [aws_vpc.main.cidr_block]  # Restrict access to resources within the VPC
  }

  # Egress rule to allow all outbound traffic
  egress {
    from_port   = 0  # Allow all outbound traffic (no restriction on port range)
    to_port     = 0  # Same as from_port, allowing all outbound traffic
    protocol    = "-1"  # "-1" means all protocols are allowed
    cidr_blocks = ["0.0.0.0/0"]  # Allow outbound traffic to any destination
  }

  tags = {
    Name = "endpoint-sg"  # Tag for identifying the security group
  }
}

# Systems Manager endpoint for Session Manager
# Enables EC2 instances in the private subnet to communicate with Systems Manager.
resource "aws_vpc_endpoint" "ssm" {
    vpc_id              = aws_vpc.main.id
    service_name        = "com.amazonaws.ap-northeast-1.ssm"
    vpc_endpoint_type   = "Interface"
    subnet_ids          = [aws_subnet.private.id]
    security_group_ids  = [aws_security_group.endpoint_sg.id]
    private_dns_enabled = true

    tags = {
        Name = "ssm-endpoint"
    }
}

# Systems Manager endpoint for SSM Messages
# Required for EC2 instances to send/receive messages from Systems Manager.
resource "aws_vpc_endpoint" "ssmmessages" {
    vpc_id              = aws_vpc.main.id
    service_name        = "com.amazonaws.ap-northeast-1.ssmmessages"
    vpc_endpoint_type   = "Interface"
    subnet_ids          = [aws_subnet.private.id]
    security_group_ids  = [aws_security_group.endpoint_sg.id]
    private_dns_enabled = true

    tags = {
        Name = "ssmmessages-endpoint"
    }
}

# Systems Manager endpoint for EC2 Messages
# Enables EC2 instances to communicate with Systems Manager for instance management.
resource "aws_vpc_endpoint" "ec2messages" {
    vpc_id              = aws_vpc.main.id
    service_name        = "com.amazonaws.ap-northeast-1.ec2messages"
    vpc_endpoint_type   = "Interface"
    subnet_ids          = [aws_subnet.private.id]
    security_group_ids  = [aws_security_group.endpoint_sg.id]
    private_dns_enabled = true

    tags = {
        Name = "ec2messages-endpoint"
    }
}

# IAM role for EC2 to allow Systems Manager access
# This role allows the EC2 instance to communicate with Systems Manager services.
resource "aws_iam_role" "ec2_ssm_role" {
    name = "ec2-ssm-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                # The "sts:AssumeRole" action allows the EC2 instance to assume the IAM role.
                # This is required for the instance to gain the permissions defined in the role.
                Action = "sts:AssumeRole",
                Effect = "Allow",
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }
        ]
    })
}

# Attach SSM policy to the role
# This policy grants the EC2 instance permissions to interact with Systems Manager.
resource "aws_iam_role_policy_attachment" "ssm_policy" {
        role       = aws_iam_role.ec2_ssm_role.name  # Attach the policy to the EC2 IAM role
        # Attach the AmazonSSMManagedInstanceCore policy to the IAM role
        # This predefined AWS policy allows the EC2 instance to use Systems Manager features
        policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create instance profile
# An instance profile is required to associate the IAM role with the EC2 instance.
resource "aws_iam_instance_profile" "ec2_instance_profile" {
        name = "ec2-instance-profile"  # Name of the instance profile
        role = aws_iam_role.ec2_ssm_role.name  # Associate the IAM role created earlier
}

# EC2 instance in private subnet
# This instance is used to test Systems Manager functionality in the private subnet.
resource "aws_instance" "test_instance" {
        ami                    = "ami-0c1638aa346a43fe8"  # Amazon Linux 2023 AMI
        instance_type          = "t2.micro"  # Instance type (small and cost-effective)
        subnet_id              = aws_subnet.private.id  # Launch the instance in the private subnet
        iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name  # Attach the instance profile
        vpc_security_group_ids = [aws_security_group.endpoint_sg.id]  # Use the security group for endpoint access

        tags = {
                Name = "ssm-test-instance"  # Tag for identifying the instance
        }
}

# Output private IP for verification
output "instance_private_ip" {
    value = aws_instance.test_instance.private_ip
}

# Steps to evaluate whether the VPC endpoint is working:

# 1. Verify the instance is registered with Systems Manager:
#    aws ssm describe-instance-information --region ap-northeast-1

# 2. Install the AWS CLI Session Manager plugin:
#    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac_arm64/session-manager-plugin.pkg" -o "session-manager-plugin.pkg"
#    sudo installer -pkg session-manager-plugin.pkg -target /
#    sudo ln -s /usr/local/sessionmanagerplugin/bin/session-manager-plugin /usr/local/bin/session-manager-plugin

# 3. Start a session with the instance:
#    aws ssm start-session --target <target-instance-id> --region ap-northeast-1

# 4. Use commands like "ls" to verify that the endpoint is working.


# Elastic Network Interfaces (ENIs) in the context of this deployment:

# 1. ENIs are virtual network interfaces that can be attached to EC2 instances or VPC endpoints.
# 2. For the VPC endpoints (Systems Manager, SSM Messages, EC2 Messages), ENIs are automatically created in the private subnet.
#    - These ENIs allow the endpoints to communicate with the respective AWS services over the private network.
#    - Each ENI is associated with a private IP address from the subnet's CIDR block.
# 3. The security group attached to the VPC endpoints (via ENIs) ensures that only HTTPS traffic (port 443) is allowed within the VPC.
# 4. The EC2 instance in the private subnet communicates with the VPC endpoints through these ENIs, enabling secure access to Systems Manager services without requiring internet access.
# 5. ENIs are managed by AWS for the VPC endpoints, and their lifecycle is tied to the lifecycle of the endpoints.

