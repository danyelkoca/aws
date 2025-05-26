# Transit Gateway resource – acts as a central router between VPCs
resource "aws_ec2_transit_gateway" "tgw" {
  description     = "Demo TGW"
  amazon_side_asn = 64512
}

# Attachment of the "server" VPC to the Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "attach_server" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc_server.id
  subnet_ids         = [aws_subnet.subnet_server.id]
}

# Attachment of the "website" VPC to the Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "attach_website" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc_website.id
  subnet_ids         = [aws_subnet.subnet_website.id]
}

# Route in the server VPC route table pointing traffic to the website VPC via TGW
resource "aws_route" "tgw_route_server" {
  route_table_id         = aws_route_table.rt_server.id
  destination_cidr_block = aws_vpc.vpc_website.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Route in the website VPC route table pointing traffic to the server VPC via TGW
resource "aws_route" "tgw_route_website" {
  route_table_id         = aws_route_table.rt_website.id
  destination_cidr_block = aws_vpc.vpc_server.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}


## IAM role, policy attachment, and instance profile for SSM access
# IAM role for SSM access
# This is needed for EC2 instances to communicate with SSM
# This is needed for both server and website, hence keeping it in gateway.tf
resource "aws_iam_role" "ssm_role" {
  name = "ssm-role"

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
  name = "ssm-profile"
  role = aws_iam_role.ssm_role.name
}


# Outputs
output "ping_command_server_to_website" {
  description = "Ping from server to website"
  value       = "ping ${aws_instance.instance_website.private_ip}"
}

output "ping_command_website_to_server" {
  description = "Ping from website to server"
  value       = "ping ${aws_instance.instance_server.private_ip}"
}