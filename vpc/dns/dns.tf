# Create VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "main-vpc"
  }
}

# Create public subnet
resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "main-subnet"
  }
}

# Create IGW and attach to VPC
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  
  tags = {
    Name = "main-igw"
  }
}

# Create a Route Table and associate with Subnet
resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "main-rt"
  }
}

resource "aws_route_table_association" "main_rt_assoc" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_rt.id
}

# Create a Security Group within the VPC
resource "aws_security_group" "main_sg" {
  name        = "main-sg"
  description = "Allow HTTP access"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "main-sg"
  }
}

# Create an EC2 instance
resource "aws_instance" "main_instance" {
  ami                    = "ami-0c1638aa346a43fe8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.main_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl enable nginx
              systemctl start nginx
              echo "<html><body><h1>Hello from EC2 with DNS</h1></body></html>" > /usr/share/nginx/html/index.html
              echo '${filebase64("${path.module}/favicon.ico")}' | base64 -d > /var/www/html/favicon.ico
              EOF

  tags = {
    Name = "dns-demo-instance"
  }
}

output "website_url" {
  value       = "http://${aws_instance.main_instance.public_dns}"
  description = "URL to access the website using DNS hostname"
}

output "main_ec2_public_url" {
  value       = "http://${aws_instance.main_instance.public_ip}"
  description = "URL to test HTTP access to the EC2 instance"
}
