# Application Load Balancer (ALB) Infrastructure

This project sets up a highly available web infrastructure in AWS using Terraform. It demonstrates how to create a secure and scalable setup with Application Load Balancer (ALB) distributing traffic to EC2 instances in private subnets.

## Architecture Overview

### VPC and Network Setup

- **VPC**:

  - CIDR: 10.0.0.0/16
  - DNS hostnames and DNS support enabled

- **Subnets**:
  - **Public Subnets** (for ALB and NAT Gateway):
    - Public Subnet 1: 10.0.1.0/24 (ap-northeast-1a)
    - Public Subnet 2: 10.0.2.0/24 (ap-northeast-1c)
  - **Private Subnets** (for EC2 instances):
    - Private Subnet 1: 10.0.3.0/24 (ap-northeast-1a)
    - Private Subnet 2: 10.0.4.0/24 (ap-northeast-1c)

### Application Load Balancer (ALB)

- Internet-facing ALB
- Deployed across two public subnets for high availability
- HTTP listener on port 80
- Round-robin load balancing algorithm
- Health checks configured to monitor instance health

### EC2 Instances

- Two t2.micro instances running Amazon Linux 2023
- Deployed in private subnets
- Each instance runs nginx web server
- Color-coded web pages for easy identification:
  - Server 1: Blue (ap-northeast-1a)
  - Server 2: Green (ap-northeast-1c)

### NAT Gateway

- Single NAT Gateway in public subnet 1
- Enables internet access for EC2 instances in private subnets
- Shares the same public subnet as the ALB

### Security

- **EC2 Instances**:

  - Located in private subnets
  - No direct internet access
  - Outbound internet access via NAT Gateway
  - Managed via AWS Systems Manager (SSM)

- **Security Groups**:
  - ALB security group: Allows inbound HTTP (port 80)
  - EC2 security group: Allows inbound traffic from ALB

### Management

- AWS Systems Manager (SSM) enabled for instance management
- No need for bastion hosts or SSH key pairs
- IAM roles and instance profiles configured for SSM access

## File Structure

- `main.tf`: VPC, subnets, NAT Gateway, and EC2 instances
- `alb.tf`: Application Load Balancer and target group configuration
- `sg.tf`: Security group definitions
- `ssm.tf`: Systems Manager IAM roles and policies

## Outputs

- ALB DNS name for accessing the web servers
- Instance IDs for SSM session management

## Environment

- Region: ap-northeast-1 (Tokyo)
- Availability Zones: ap-northeast-1a and ap-northeast-1c
