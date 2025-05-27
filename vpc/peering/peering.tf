## NOTE THIS EXAMPLE HAS A FULLY WORKING SSM SETUP.
# SEE VPCS FOR FURTHER INFO

# Peering
resource "aws_vpc_peering_connection" "peer_a_b" {
  vpc_id      = aws_vpc.vpc_a.id
  peer_vpc_id = aws_vpc.vpc_b.id
  auto_accept = true

  tags = {
    Name = "vpc-peer-a-b"
  }
}

# Add route to VPC B in VPC A's route table
resource "aws_route" "route_a_to_b" {
  route_table_id            = aws_route_table.rt_a.id
  destination_cidr_block    = aws_vpc.vpc_b.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_a_b.id
}

# Add route to VPC A in VPC B's route table
resource "aws_route" "route_b_to_a" {
  route_table_id            = aws_route_table.rt_b.id
  destination_cidr_block    = aws_vpc.vpc_a.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_a_b.id
}


# SSM
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

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-profile"
  role = aws_iam_role.ssm_role.name
}


# Outputs
output "ping_command_a_to_b" {
  description = "Ping from a to b"
  value       = "ping ${aws_instance.instance_b.private_ip}"
}

output "ping_command_b_to_a" {
  description = "Ping from b to a"
  value       = "ping ${aws_instance.instance_a.private_ip}"
}
