## AWS Systems Manager – Session Manager Overview

### What is Session Manager?

Session Manager is a capability of AWS Systems Manager (SSM) that provides secure and auditable shell access to EC2 instances without requiring SSH, bastion hosts, or inbound ports. It allows direct CLI-based or browser-based interactive sessions to managed instances.

### What Did It Replace?

Traditionally, administrators used bastion hosts to access EC2 instances in private subnets via SSH. Session Manager replaces this need, offering a more secure, scalable, and auditable approach without the complexity of managing SSH keys or public IPs.

### Comparison: Session Manager vs Bastion Host

| Feature        | Session Manager                         | Bastion Host                        |
| -------------- | --------------------------------------- | ----------------------------------- |
| Security       | No inbound ports; IAM-based access      | Requires open SSH port (22)         |
| Cost           | No compute cost; minimal SSM usage cost | Ongoing EC2 and potential NAT costs |
| Auditing       | Native CloudWatch/S3 logging            | Manual logging setup                |
| Access Control | IAM policies                            | Key-based or jump user              |
| Scalability    | Fully managed                           | Manual scaling and maintenance      |
| Ease of Use    | CLI, Console, SDK support               | SSH client setup required           |

### AWS Solutions Architect – Professional Exam Topics

- Secure management of EC2 in private subnets
- Use cases for Session Manager over bastion hosts
- IAM roles and permissions for SSM
- Network configurations for SSM (VPC endpoints, DNS)
- Logging and auditing with CloudWatch
- SSM Agent requirements
- Session Manager integration with automation and Run Command

---

## Typical AWS SA Pro Exam Answers

- **Why use Session Manager over a Bastion Host?**  
  Session Manager provides secure, auditable access to EC2 instances without requiring open inbound ports or public IPs. It reduces operational overhead and attack surface, and simplifies compliance through native logging and IAM-based access control.

- **How do you enable Session Manager in a private subnet?**  
  Deploy VPC interface endpoints for `ssm`, `ssmmessages`, and `ec2messages`. Ensure instances have the SSM Agent installed, the proper IAM role attached, and a security group allowing HTTPS (port 443) to the VPC endpoints.

- **What IAM permissions are required for SSM access?**  
  Attach the `AmazonSSMManagedInstanceCore` policy to the EC2 IAM role. For administrators initiating sessions, assign `ssm:StartSession`, `ssm:DescribeInstanceInformation`, and related permissions.

- **How can you audit SSM sessions?**  
  Enable logging to Amazon CloudWatch Logs or S3 by configuring the Session Manager preferences in the Systems Manager console or via AWS CLI.

- **What are security advantages of Session Manager?**  
  Eliminates need for SSH, avoids public IP exposure, no key pair management, logs all session activity, integrates with IAM and CloudTrail for access control and auditing.
