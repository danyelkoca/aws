resource "aws_vpc" "vpc_server" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "vpc_server" }
}

resource "aws_subnet" "subnet_server" {
  vpc_id            = aws_vpc.vpc_server.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags              = { Name = "subnet_server" }
}

# Security Group for server instance and SSM endpoints
resource "aws_security_group" "sg_server" {
  name        = "sg_server"
  description = "Allow ICMP and HTTPS for SSM"
  vpc_id      = aws_vpc.vpc_server.id

  # from ping from other VPC
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.20.0.0/16"]
  }

  # for ssm
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_server.cidr_block]
  }

  # No explicit egress block
  # Egress rules are automatically created to allow all outbound traffic

  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  tags = {
    Name = "sg_server"
  }
}

resource "aws_instance" "instance_server" {
  ami                    = "ami-0c1638aa346a43fe8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_server.id
  vpc_security_group_ids = [aws_security_group.sg_server.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  tags = { Name = "instance_server" }
}

## Route table needed for transit gateway
resource "aws_route_table" "rt_server" {
  vpc_id = aws_vpc.vpc_server.id
  tags   = { Name = "rt_server" }
}

resource "aws_route_table_association" "rta_server" {
  subnet_id      = aws_subnet.subnet_server.id
  route_table_id = aws_route_table.rt_server.id
}

## SSM stuff
resource "aws_vpc_endpoint" "ssm_server" {
  vpc_id              = aws_vpc.vpc_server.id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet_server.id]
  security_group_ids  = [aws_security_group.sg_server.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages_server" {
  vpc_id              = aws_vpc.vpc_server.id
  service_name        = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet_server.id]
  security_group_ids  = [aws_security_group.sg_server.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages_server" {
  vpc_id              = aws_vpc.vpc_server.id
  service_name        = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet_server.id]
  security_group_ids  = [aws_security_group.sg_server.id]
  private_dns_enabled = true
}
