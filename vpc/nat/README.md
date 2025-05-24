# NAT Gateway Overview

## What is NAT?

NAT (Network Address Translation) Gateway is an AWS-managed service that enables instances in a private subnet to connect to the internet or other AWS services, but prevents the internet from initiating connections with those instances.

## When Should It Be Used?

Use a NAT Gateway when:

- You have EC2 instances in private subnets that need outbound internet access.
- You want to download software updates, pull Docker images, or access AWS APIs from private instances without exposing them to the internet.

## Benefits

- **Security**: Instances remain in a private subnet with no public IPs.
- **Managed**: AWS handles availability, scalability, and maintenance.
- **Simplicity**: Automatically scales up to accommodate bandwidth.

## Cost Considerations

- **Hourly Cost**: ~\$0.045/hour per NAT Gateway
- **Data Processed**: ~\$0.045 per GB of data processed
- Costs increase with multi-AZ deployments and higher outbound data usage.

---

## Comparison: Gateway vs Interface vs NAT Gateway

| Feature                | Gateway Endpoint                | Interface Endpoint                             | NAT Gateway                            |
| ---------------------- | ------------------------------- | ---------------------------------------------- | -------------------------------------- |
| **Primary Use**        | Private access to S3 / DynamoDB | Private access to AWS services (e.g. SSM)      | Outbound internet from private subnets |
| **Supported Services** | S3, DynamoDB only               | Most AWS services (SSM, Secrets Manager, etc.) | Any internet-accessible service        |
| **Traffic Direction**  | VPC → AWS service               | VPC → AWS service                              | VPC → Internet (egress only)           |
| **Access Type**        | VPC-only                        | VPC + Peering + Direct Connect                 | Outbound only, no inbound              |
| **Cost**               | Free                            | ~\$0.01/hour + data charges                    | ~$0.045/hour + $0.045/GB               |
| **Security Groups**    | Not required                    | Required                                       | Not applicable                         |
| **Resource Type**      | Route table entry               | Elastic Network Interface (ENI)                | Managed gateway                        |
| **Availability**       | Highly available by default     | Zonal (1 per AZ)                               | Zonal (replicate for HA)               |
| **Setup Complexity**   | Simple                          | Medium (SGs, ENIs)                             | Medium (per AZ setup, route table)     |
| **Use Case Example**   | EC2 → S3 without internet       | EC2 → Secrets Manager without internet         | EC2 → Internet without public IP       |
