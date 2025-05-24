# NAT Instance Setup and Comparison with NAT Gateway

**Deprecated Notice**: As of 2023, AWS no longer recommends using NAT instances. Customers are strongly encouraged to use NAT Gateways for secure, scalable, and managed internet access from private subnets. AWS documentation and Amazon Linux 2023 no longer include official NAT instance support.

---

## Use Case Summary

| Option                    | Use Case                                                                                                      |
| ------------------------- | ------------------------------------------------------------------------------------------------------------- |
| **NAT Gateway**           | Production environments needing high availability and performance.                                            |
| **NAT Instance** (legacy) | Cost-sensitive dev/test setups where traffic inspection or OS-level control was required. **Now deprecated.** |

---

## Comparison: NAT Gateway vs NAT Instance

| Feature                         | NAT Gateway                | NAT Instance (Deprecated)                 |
| ------------------------------- | -------------------------- | ----------------------------------------- |
| Managed by AWS                  | Yes                        | No                                        |
| High availability               | Yes (multi-AZ support)     | No (single AZ unless manually configured) |
| Auto scaling                    | Yes                        | No                                        |
| Maintenance required            | No                         | Yes (patching, monitoring)                |
| Cost                            | Higher (per hour + per GB) | Lower (EC2 cost + transfer)               |
| Custom routing, inspection      | No                         | Yes (via iptables, etc.)                  |
| Source/destination check config | N/A                        | Must disable manually                     |
| Support status                  | Supported                  | **Deprecated**                            |

---

## Recommendation

Use **NAT Gateway** for all modern deployments.  
Avoid NAT instances unless explicitly required for legacy support.

---

## Legacy NAT Instance Setup (For Reference Only)

Even though NAT Instances are deprecated and no longer recommended by AWS, they can still be set up manually in non-production environments for specific legacy or testing use cases.

### Steps to Set Up a NAT Instance:

1. **Launch an EC2 Instance**:

   - Use an Amazon Linux AMI (not Amazon Linux 2023).
   - Place it in a **public subnet** with a route to an Internet Gateway.
   - Assign an Elastic IP.

2. **Configure the Instance**:

   - Disable Source/Destination Check:
     ```
     aws ec2 modify-instance-attribute --instance-id i-xxxxxx --no-source-dest-check
     ```

3. **Update Route Tables**:

   - In your private subnet's route table, add a route for `0.0.0.0/0` pointing to the NAT instance ID.

4. **Optional**: Set up iptables for traffic forwarding and NAT behavior.

> **Warning**: AWS provides no support or updates for NAT Instances. Use only if NAT Gateway is not viable.
