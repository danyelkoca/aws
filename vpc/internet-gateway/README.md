# AWS VPC with Internet Gateway Tutorial

This example demonstrates how to create a VPC with a public subnet, internet gateway, and an EC2 instance serving a simple HTML page.

## Components

1. **VPC** - A virtual network with CIDR block 10.0.0.0/16
2. **Public Subnet** - A subnet with CIDR 10.0.1.0/24 that can access the internet
3. **Internet Gateway** - Enables internet connectivity for the VPC
4. **Route Table** - Routes traffic from the subnet to the internet gateway
5. **Security Group** - Controls inbound/outbound traffic for the EC2 instance (HTTP only)
6. **EC2 Instance** - A t2.micro instance running Apache with a simple HTML page

## Prerequisites

1. AWS CLI configured with your credentials
2. Terraform installed

## Usage

1. Initialize Terraform:

   ```
   terraform init
   ```

2. Apply the configuration:

   ```
   terraform apply
   ```

3. After deployment:
   - You'll get a URL to access your web server
   - Open the URL in your browser to see a simple "Hello from EC2" page

## Clean Up

To delete all resources:

```
terraform destroy
```

## Architecture

```
┌────────────────────────────VPC (10.0.0.0/16)────────────────────────┐
│                                                                     │
│   ┌─────────────────Public Subnet (10.0.1.0/24)─────────────────┐   │
│   │                                                             │   │
│   │                    ┌──────────────┐                         │   │
│   │                    │  EC2 Instance│                         │   │
│   │                    │   (Apache)   │                         │   │
│   │                    └──────────────┘                         │   │
│   │                           ▲                                 │   │
│   │                           │                                 │   │
│   └───────────────────────────┼─────────────────────────────────┘   │
│                               │                                     │
│                         Route Table                                 │
│                               │                                     │
│                    Internet Gateway                                 │
│                               │                                     │
└───────────────────────────────┼─────────────────────────────────────┘
                                │
                                ▼
                            Internet
```

Note: The Internet Gateway (IGW) is attached to the VPC and the route table directs traffic from the public subnet through the IGW. This allows resources in the public subnet to communicate with the internet.
