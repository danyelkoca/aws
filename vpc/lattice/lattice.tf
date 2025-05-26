# VPC Lattice Demo
provider "aws" {
  region = "ap-northeast-1"
}

# Create a VPC Lattice Service Network
resource "aws_vpclattice_service_network" "example_network" {
  name      = "example-service-network"
  auth_type = "NONE" # No authentication; use AWS_IAM for production

  tags = {
    Name = "LatticeNetwork"
  }
}

# Associate producer VPC with the service network
resource "aws_vpclattice_service_network_vpc_association" "producer_assoc" {
  service_network_identifier = aws_vpclattice_service_network.example_network.id
  vpc_identifier             = aws_vpc.producer.id

  tags = {
    Name = "ProducerAssoc"
  }
}

# Associate consumer VPC with the service network
resource "aws_vpclattice_service_network_vpc_association" "consumer_assoc" {
  service_network_identifier = aws_vpclattice_service_network.example_network.id
  vpc_identifier             = aws_vpc.consumer.id

  tags = {
    Name = "ConsumerAssoc"
  }
}

# Create a target group for the producer
resource "aws_vpclattice_target_group" "producer_tg" {
  name = "producer-tg"
  type = "INSTANCE" # Targets EC2 instances

  config {
    port           = 80
    protocol       = "HTTP"
    vpc_identifier = aws_vpc.producer.id
  }

  tags = {
    Name = "ProducerTargetGroup"
  }
}

# Create a service for the producer
resource "aws_vpclattice_service" "producer_service" {
  name      = "producer-service"
  auth_type = "NONE" # No authentication; for demo purposes

  tags = {
    Name = "ProducerService"
  }
}

# Associate the service with the service network
resource "aws_vpclattice_service_network_service_association" "association" {
  service_identifier         = aws_vpclattice_service.producer_service.id
  service_network_identifier = aws_vpclattice_service_network.example_network.id

  tags = {
    Name = "LatticeServiceAssociation"
  }
}

# Output the DNS name of the Lattice service
output "lattice_service_dns" {
  description = "DNS name of the Lattice service"
  value       = aws_vpclattice_service.producer_service.dns_entry[0].domain_name
}

# Steps:
# 1. Add a listener in Lattice
# 2. Attach targets to the target group
# 3. Test using curl with lattice_service_dns