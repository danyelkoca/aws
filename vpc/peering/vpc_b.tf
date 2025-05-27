resource "aws_vpc" "vpc_b" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "vpc_b" }
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.vpc_b.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags              = { Name = "subnet_b" }
}

# Security Group for B instance and SSM endpoints
resource "aws_security_group" "sg_b" {
  name        = "sg_b"
  description = "Allow ICMP and TCP for SSM"
  vpc_id      = aws_vpc.vpc_b.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    self      = true
  }

  # You need to have this rule for SSM to work
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_b"
  }
}

resource "aws_instance" "instance_b" {
  ami                    = "ami-0c1638aa346a43fe8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_b.id
  vpc_security_group_ids = [aws_security_group.sg_b.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  tags = { Name = "instance_b" }
}

## Route table needed for transit gateway
resource "aws_route_table" "rt_b" {
  vpc_id = aws_vpc.vpc_b.id
  tags   = { Name = "rt_b" }
}

resource "aws_route_table_association" "rta_b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.rt_b.id
}

## SSM stuff
resource "aws_vpc_endpoint" "ssm_b" {
  vpc_id              = aws_vpc.vpc_b.id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet_b.id]
  security_group_ids  = [aws_security_group.sg_b.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages_b" {
  vpc_id              = aws_vpc.vpc_b.id
  service_name        = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet_b.id]
  security_group_ids  = [aws_security_group.sg_b.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages_b" {
  vpc_id              = aws_vpc.vpc_b.id
  service_name        = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet_b.id]
  security_group_ids  = [aws_security_group.sg_b.id]
  private_dns_enabled = true
}
