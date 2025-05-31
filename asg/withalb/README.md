# Auto Scaling Group with Application Load Balancer

This project demonstrates a production-ready AWS infrastructure using Terraform, featuring an Auto Scaling Group (ASG) behind an Application Load Balancer (ALB) with proper networking and security configurations.

## Architecture Overview

```plaintext
                                     │
                                     ▼
                            Internet Traffic
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────┐
│                        VPC                              │
│                                                        │
│   ┌─────────────┐                    ┌─────────────┐   │
│   │  Public-1   │◄──────ALB─────────►│  Public-2   │   │
│   │             │                    │             │   │
│   │    NAT     │                    │             │   │
│   │  Gateway   │                    │             │   │
│   └─────────────┘                    └─────────────┘   │
│          │                                  │          │
│          ▼                                  ▼          │
│   ┌─────────────┐                    ┌─────────────┐   │
│   │ Private-1   │                    │ Private-2   │   │
│   │             │                    │             │   │
│   │   ASG EC2   │◄──────────────────►│   ASG EC2   │   │
│   │ Instances   │                    │ Instances   │   │
│   └─────────────┘                    └─────────────┘   │
│          │                                  │          │
│          └──────────────┐      ┌───────────┘          │
│                         ▼      ▼                       │
│                   ┌──────────────────┐                 │
│                   │   VPC Endpoints  │                 │
│                   │   (SSM Access)   │                 │
│                   └──────────────────┘                 │
└─────────────────────────────────────────────────────────┘
```

## Infrastructure Components

### Networking

- **VPC**: 10.0.0.0/16

  - Enable DNS hostnames and DNS support
  - Spans multiple Availability Zones for high availability

- **Public Subnets**:

  - Public-1: 10.0.1.0/24 (ap-northeast-1a)
  - Public-2: 10.0.2.0/24 (ap-northeast-1c)
  - Houses ALB and NAT Gateway
  - Auto-assigns public IPs

- **Private Subnets**:

  - Private-1: 10.0.3.0/24 (ap-northeast-1a)
  - Private-2: 10.0.4.0/24 (ap-northeast-1c)
  - Houses EC2 instances launched by ASG
  - No public IP assignment
  - DNS hostnames and DNS support enabled

- **Subnets**:
  - **Public Subnets** (for ALB and NAT Gateway):
    - Public Subnet 1: 10.0.1.0/24 (ap-northeast-1a)
    - Public Subnet 2: 10.0.2.0/24 (ap-northeast-1c)
  - **Private Subnets** (for ASG instances):
    - Private Subnet 1: 10.0.3.0/24 (ap-northeast-1a)
    - Private Subnet 2: 10.0.4.0/24 (ap-northeast-1c)

### Auto Scaling Group

- Launch Template with Amazon Linux 2023
- Minimum size: 2 instances
- Maximum size: 4 instances
- Desired capacity: 2 instances
- Health check type: ELB
- Deployed across two private subnets

### Application Load Balancer (ALB)

- Internet-facing ALB
- Deployed across two public subnets for high availability
- HTTP listener on port 80
- Health checks configured to monitor instance health

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

- `main.tf`: VPC, subnets, NAT Gateway, ASG, and ALB configuration
- `sg.tf`: Security group definitions
- `ssm.tf`: Systems Manager IAM roles and policies

## High Availability Design

This infrastructure is designed for high availability across multiple Availability Zones (AZs):

### Multi-AZ Components

1. **Application Load Balancer (ALB)**:

   - Deployed across two AZs (ap-northeast-1a and 1c)
   - If one AZ fails, ALB continues to operate in the other AZ
   - Automatic failover with no manual intervention needed

2. **Auto Scaling Group (ASG)**:

   - Spans both ap-northeast-1a and 1c private subnets
   - Automatically distributes instances across AZs
   - If one AZ fails, ASG launches new instances in the healthy AZ
   - Maintains desired capacity across available AZs

3. **Networking**:
   - Public subnets in both AZs for ALB high availability
   - Private subnets in both AZs for EC2 instance distribution
   - Single NAT Gateway (cost-optimized, can be dual NAT for higher availability)

### Failure Scenarios

1. **Single AZ Failure**:

   - ALB continues serving traffic from the other AZ
   - ASG launches replacement instances in the healthy AZ
   - Application remains available with minimal disruption

2. **Instance Failure**:

   - Health checks detect failed instances
   - ASG automatically replaces unhealthy instances
   - ALB routes traffic only to healthy instances

3. **Availability Zone Balance**:
   - ASG maintains even instance distribution
   - ALB provides cross-zone load balancing
   - Traffic is distributed evenly across available instances

## Key Differences from ALB-only Setup

1. Uses Launch Template instead of direct EC2 instances
2. Auto Scaling Group manages instance lifecycle
3. Target group automatically registers/deregisters instances
4. No manual target group attachments needed
5. Instances can scale based on demand

## Outputs

- ALB DNS name for accessing the web application

## Environment

- Region: ap-northeast-1 (Tokyo)
- Availability Zones: ap-northeast-1a and ap-northeast-1c
