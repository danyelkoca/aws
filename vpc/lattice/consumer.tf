resource "aws_vpc" "consumer" {
  cidr_block = "10.1.0.0/16"  # Separate address space for consumer
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "ConsumerVPC"
  }
}

resource "aws_subnet" "consumer_subnet" {
  vpc_id            = aws_vpc.consumer.id
  cidr_block        = "10.1.1.0/24"                 # Subnet for consumer instances
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "ConsumerSubnet"
  }
}


resource "aws_security_group" "consumer_endpoint_sg" {
  name        = "consumer-endpoint-sg"
  description = "Allow HTTPS within VPC for interface endpoints"
  vpc_id      = aws_vpc.consumer.id

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
    Name = "ConsumerEndpointSG"
  }
}


resource "aws_vpc_endpoint" "consumer_ssm" {
  vpc_id            = aws_vpc.consumer.id
  service_name      = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.consumer_subnet.id]
  security_group_ids = [aws_security_group.consumer_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "SSMEndpoint"
  }
}

resource "aws_vpc_endpoint" "consumer_ssmmessages" {
  vpc_id            = aws_vpc.consumer.id
  service_name      = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.consumer_subnet.id]
  security_group_ids = [aws_security_group.consumer_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "SSMMessagesEndpoint"
  }
}

resource "aws_vpc_endpoint" "consumer_ec2messages" {
  vpc_id            = aws_vpc.consumer.id
  service_name      = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.consumer_subnet.id]
  security_group_ids = [aws_security_group.consumer_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "EC2MessagesEndpoint"
  }
}



resource "aws_iam_role" "consumer_ssm_role" {
  name = "consumer-ssm-role"

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
resource "aws_iam_role_policy_attachment" "consumer_ssm_policy" {
  role       = aws_iam_role.consumer_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create instance profile
resource "aws_iam_instance_profile" "consumer_ssm_instance_profile" {
  name = "consumer-ssm-profile"
  role = aws_iam_role.consumer_ssm_role.name
}

resource "aws_instance" "consumer_instance" {
  ami                    = "ami-0c1638aa346a43fe8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.consumer_subnet.id
  vpc_security_group_ids = [aws_security_group.consumer_endpoint_sg.id]
  associate_public_ip_address = true
  iam_instance_profile   = aws_iam_instance_profile.consumer_ssm_instance_profile.name

  tags = {
    Name = "ConsumerTestInstance"
  }
}
