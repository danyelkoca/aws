resource "aws_vpc" "producer" {
  cidr_block = "10.0.0.0/16"  # Large address space for producer services
  enable_dns_support   = true    # Required for VPC interface endpoints
  enable_dns_hostnames = true

  tags = {
    Name = "ProducerVPC"
  }
}

resource "aws_subnet" "producer_subnet" {
  vpc_id            = aws_vpc.producer.id
  cidr_block        = "10.0.1.0/24"                 # Subnet for producer instances
  availability_zone = "ap-northeast-1a"             # AZ chosen for resource placement

  tags = {
    Name = "ProducerSubnet"
  }
}


resource "aws_vpc_endpoint" "producer_ssm" {
  vpc_id            = aws_vpc.producer.id
  service_name      = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.producer_subnet.id]
  security_group_ids = [aws_security_group.producer_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "SSMEndpoint"
  }
}

resource "aws_vpc_endpoint" "producer_ssmmessages" {
  vpc_id            = aws_vpc.producer.id
  service_name      = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.producer_subnet.id]
  security_group_ids = [aws_security_group.producer_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "SSMMessagesEndpoint"
  }
}

resource "aws_vpc_endpoint" "producer_ec2messages" {
  vpc_id            = aws_vpc.producer.id
  service_name      = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.producer_subnet.id]
  security_group_ids = [aws_security_group.producer_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "EC2MessagesEndpoint"
  }
}

resource "aws_security_group" "producer_endpoint_sg" {
  name        = "producer-endpoint-sg"
  description = "Allow HTTPS within VPC for interface endpoints"
  vpc_id      = aws_vpc.producer.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ProducerEndpointSG"
  }
}

# IAM role for SSM access
resource "aws_iam_role" "ssm_role" {
  name = "producer-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach SSM policy
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create instance profile
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "producer-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "producer_instance" {
  ami                    = "ami-0c1638aa346a43fe8"
  instance_type          = "t2.micro"              # Low-cost instance for demo
  subnet_id              = aws_subnet.producer_subnet.id
  vpc_security_group_ids = [aws_security_group.producer_endpoint_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  # User data script to start a simple HTTP server serving a greeting
  user_data = <<-EOF
              #!/bin/bash
              cd /home/ec2-user
              echo "Hello from Producer" > index.html
              nohup python3 -m http.server 80 > server.log 2>&1 &
              EOF

  tags = {
    Name = "ProducerInstance"
  }
}


