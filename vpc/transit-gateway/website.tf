resource "aws_vpc" "vpc_website" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "vpc_website" }
}

resource "aws_subnet" "subnet_website" {
  vpc_id            = aws_vpc.vpc_website.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags              = { Name = "subnet_website" }
}

# Security Group for website instance and SSM endpoints
resource "aws_security_group" "sg_website" {
  name        = "sg_website"
  description = "Allow ICMP and HTTPS for SSM"
  vpc_id      = aws_vpc.vpc_website.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_website.cidr_block]
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
    Name = "sg_website"
  }
}

resource "aws_instance" "instance_website" {
  ami                    = "ami-0c1638aa346a43fe8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_website.id
  vpc_security_group_ids = [aws_security_group.sg_website.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  tags = { Name = "instance_website" }
}

## Route table needed for transit gateway
resource "aws_route_table" "rt_website" {
  vpc_id = aws_vpc.vpc_website.id
  tags   = { Name = "rt_website" }
}

resource "aws_route_table_association" "rta_website" {
  subnet_id      = aws_subnet.subnet_website.id
  route_table_id = aws_route_table.rt_website.id
}

## SSM stuff
resource "aws_vpc_endpoint" "ssm_website" {
  vpc_id              = aws_vpc.vpc_website.id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet_website.id]
  security_group_ids  = [aws_security_group.sg_website.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages_website" {
  vpc_id              = aws_vpc.vpc_website.id
  service_name        = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet_website.id]
  security_group_ids  = [aws_security_group.sg_website.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages_website" {
  vpc_id              = aws_vpc.vpc_website.id
  service_name        = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet_website.id]
  security_group_ids  = [aws_security_group.sg_website.id]
  private_dns_enabled = true
}
