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
    Name = "asg-vpc"
  }
}

# Private Subnets (for ASG)
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

# Public Subnets (for ALB and NAT)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Public Route Table Associations
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
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
# NAT Gateway       #
######################

resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "main-nat-gateway"
  }
}

######################
# Launch Template   #
######################

# Launch Template is required for ASG as it defines the instance configuration blueprint
# It's like a recipe that tells ASG how to create new instances, including:
# - Which AMI to use
# - Instance type
# - Network settings
# - IAM roles
# - User data (bootstrap script)
# Benefits over direct EC2 configuration:
# - Versioning support (can roll back if needed)
# - Reusability (can be used by multiple ASGs)
# - Consistency (ensures all instances are identical)

resource "aws_launch_template" "web" {
  name_prefix   = "web-template"  # Using prefix allows multiple versions
  image_id      = data.aws_ami.amazon_linux.id  # Latest Amazon Linux 2023
  instance_type = "t2.micro"  # Free tier eligible

  # Network configuration - placing instances in private subnets
  network_interfaces {
    associate_public_ip_address = false  # No public IPs needed as we're behind ALB
    security_groups            = [aws_security_group.ec2.id]  # Security group allowing traffic from ALB
  }

  # IAM profile for Systems Manager access - allows management without SSH
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx

              # Get IMDSv2 token
              TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

              # Use token to get instance metadata
              INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
              AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

              # Write HTML content using eval for proper variable substitution
              eval "cat <<EOT > /usr/share/nginx/html/index.html
              <!DOCTYPE html>
              <html>
              <head><meta charset='UTF-8'><title>Updated Page</title></head>
              <body style='background-color:#f9f9f9;'>
                <h1>🚀 Updated Version Served from Instance \$INSTANCE_ID</h1>
                <p>This is a refreshed page from the Auto Scaling Group</p>
                <p>Running in Availability Zone: \$AZ</p>
              </body>
              </html>
              EOT"

              systemctl restart nginx
              systemctl enable nginx
              EOF
  )

  tags = {
    Name = "web-server-template"
  }
}

######################
# Auto Scaling Group #
######################

resource "aws_autoscaling_group" "web" {
  name                = "web-asg"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  target_group_arns   = [aws_lb_target_group.web.arn]
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  health_check_type   = "ELB"
  health_check_grace_period = 300  # Time (in seconds) to wait before checking the health status of new instances
  default_cooldown = 30           # Time (in seconds) to wait after a scaling activity before starting another one. Default is 300 seconds.

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web-server"
    propagate_at_launch = true
  }
}

######################
# ALB               #
######################

resource "aws_lb" "web" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "web-alb"
  }
}

resource "aws_lb_target_group" "web" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 10
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    timeout             = 5
    unhealthy_threshold = 3
  }

  # Enable stickiness if needed
  stickiness {
    type = "lb_cookie"
    enabled = false
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

######################
# Outputs           #
######################

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = "http://${aws_lb.web.dns_name}"
}