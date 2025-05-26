# AWS Network Infrastructure: VPC, Subnet, IGW, Route Table, NACL, SG, and EC2 Setup

This guide explains how to provision a basic AWS network and compute stack using Terraform or AWS CLI. The structure follows best practice: **VPC → Subnet → Internet Gateway → Route Table → NACL → Security Group → EC2**.

---

## Architecture Overview

- **VPC**: Defines the private network boundary (e.g., `10.0.0.0/16`).
- **Subnet**: Subdivides the VPC into smaller address blocks (e.g., `10.0.1.0/24`), each in one AZ.
- **Internet Gateway (IGW)**: Enables communication between VPC resources and the public internet.
- **Route Table**: Directs subnet traffic to the IGW for internet access (`0.0.0.0/0`).
- **Network ACL (NACL)**: Stateless firewall at subnet level; controls all ingress/egress.
- **Security Group (SG)**: Stateful firewall at instance level; controls allowed protocols/ports.
- **EC2 Instance**: Virtual machine in public subnet, with HTTP and SSH access enabled.

---

## Step-by-Step Setup

### 1. Create the VPC

- **CIDR block**: `10.0.0.0/16` (private address space for all subnets/resources)

```bash
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=Main-VPC}]'
```

**Output** (shortened):

```json
{ "Vpc": { "VpcId": "vpc-xxxxxxxx", "CidrBlock": "10.0.0.0/16" } }
```

### 2. Create a Public Subnet

- **Subnet CIDR**: `10.0.1.0/24` (subset of VPC, 256 IPs, one AZ)
- Enable **auto-assign public IP** for all launched instances.

```bash
aws ec2 create-subnet --vpc-id vpc-xxxxxxxx --cidr-block 10.0.1.0/24 --availability-zone ap-northeast-1c --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Main-Subnet}]'
aws ec2 modify-subnet-attribute --subnet-id subnet-xxxxxxxx --map-public-ip-on-launch
```

**Explanation**:  
_The subnet's CIDR must fit within the VPC's block. Auto-assigning public IPs ensures instances are internet-reachable if routing allows._

### 3. Attach an Internet Gateway

```bash
aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=Main-IGW}]'
aws ec2 attach-internet-gateway --internet-gateway-id igw-xxxxxxxx --vpc-id vpc-xxxxxxxx
```

_The IGW enables public internet access for resources routed through it._

### 4. Create and Associate a Route Table

- Add a route for all outbound IPv4 (`0.0.0.0/0`) via IGW.

```bash
aws ec2 create-route-table --vpc-id vpc-xxxxxxxx --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Main-RouteTable}]'
aws ec2 create-route --route-table-id rtb-xxxxxxxx --destination-cidr-block 0.0.0.0/0 --gateway-id igw-xxxxxxxx
aws ec2 associate-route-table --subnet-id subnet-xxxxxxxx --route-table-id rtb-xxxxxxxx
```

_This makes the subnet a "public subnet" as it can route to the internet._

### 5. Create and Associate a Custom Network ACL

- **NACL**: Stateless firewall at subnet level.
- **Rule logic**:
  - Deny all ingress from your IP (for testing, e.g., `<your-ip>/32`),
  - Allow all other ingress and all egress.

```bash
aws ec2 create-network-acl --vpc-id vpc-xxxxxxxx --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=Main-ACL}]'
aws ec2 create-network-acl-entry --network-acl-id acl-xxxxxxxx --rule-number 90 --protocol -1 --rule-action deny --egress false --cidr-block <your-ip>/32
aws ec2 create-network-acl-entry --network-acl-id acl-xxxxxxxx --rule-number 100 --protocol -1 --rule-action allow --egress false --cidr-block 0.0.0.0/0
aws ec2 create-network-acl-entry --network-acl-id acl-xxxxxxxx --rule-number 100 --protocol -1 --rule-action allow --egress true --cidr-block 0.0.0.0/0
aws ec2 replace-network-acl-association --association-id aclassoc-yyyyyyyy --network-acl-id acl-xxxxxxxx
```

**Comment**:  
_NACL rules are evaluated in number order. The deny rule for your IP takes precedence. NACLs are stateless: allow both ingress and egress for desired traffic._

### 6. Create a Security Group for EC2

- **SG**: Stateful firewall at instance level.
- Allow **HTTP (80)** from anywhere, **SSH (22)** only from your public IP.

```bash
aws ec2 create-security-group --group-name Main-SG --description "Allow HTTP and SSH" --vpc-id vpc-xxxxxxxx
aws ec2 authorize-security-group-ingress --group-id sg-xxxxxxxx --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id sg-xxxxxxxx --protocol tcp --port 22 --cidr <your-ip>/32
```

**Explanation**:  
_SGs are stateful: if you allow inbound SSH/HTTP, return traffic is automatically allowed. Restrict SSH to your IP for security._

### 7. Launch an EC2 Instance

- **AMI**: Amazon Linux 2023 (replace with valid AMI for your region)
- **Key Pair**: Must be created in advance (see below).
- **User Data**: Installs and starts nginx for HTTP testing.

```bash
aws ec2 run-instances \
  --image-id ami-xxxxxxxxxxxxxxxxx \
  --instance-type t2.micro \
  --subnet-id subnet-xxxxxxxx \
  --security-group-ids sg-xxxxxxxx \
  --key-name MainKey \
  --user-data file://nginx-user-data.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Main-Instance}]'
```

**Note**:  
_The EC2 instance will receive a public IP if the subnet is configured correctly. The user data script should install nginx and start the service._

---

## CIDR Block, Public IP, and Firewall Comments

- **CIDR Blocks**:
  - VPC (`10.0.0.0/16`): Large private space for all resources.
  - Subnet (`10.0.1.0/24`): Smaller segment, must fit within VPC.
- **Public IP**:
  - Enabled at subnet level (`map-public-ip-on-launch=true`) so instances are reachable from the internet.
- **NACL Role**:
  - Controls all traffic at the subnet edge.
  - Rules must allow both directions for desired traffic.
  - Deny rules (e.g., for your IP) take precedence if lower rule number.
- **SG Role**:
  - Controls access at instance level.
  - Allow HTTP from all, SSH from your IP only.
- **SSH/HTTP Logic**:
  - Both NACL and SG must permit traffic for access to succeed.
  - HTTP: Open to all (`0.0.0.0/0`) in both NACL and SG.
  - SSH: Open only from your IP in both NACL and SG.

---

## Example Verification

1. **Get Public IP**  
   After deployment, find the EC2's public IP in the console or via:
   ```bash
   aws ec2 describe-instances --instance-ids i-xxxxxxxx --query 'Reservations[*].Instances[*].PublicIpAddress' --output text
   ```
2. **Test HTTP Access**  
   Open in browser:
   ```
   http://<public-ip>
   ```
   _You should see the nginx welcome page._
3. **Test SSH Access**  
   Ensure you have the `path/to/keypair/pem/file` file:
   ```bash
   chmod 400 path/to/keypair/pem/file
   ssh -i path/to/keypair/pem/file ec2-user@<public-ip>
   ```
   _If your IP is allowed in SG and NACL, you will connect. If not, connection times out._

---

## Key Pair Creation (for SSH)

Create once before launching EC2:

```bash
aws ec2 create-key-pair --key-name MainKey --query 'KeyMaterial' --output text > path/to/keypair/pem/file
chmod 400 path/to/keypair/pem/file
```

---

## Clean Up Resources

Terminate and remove all resources in reverse order:

```bash
# Terminate EC2
aws ec2 terminate-instances --instance-ids i-xxxxxxxx
aws ec2 wait instance-terminated --instance-ids i-xxxxxxxx
# Disassociate and delete NACL
aws ec2 replace-network-acl-association --association-id aclassoc-yyyyyyyy --network-acl-id acl-default
aws ec2 delete-network-acl --network-acl-id acl-xxxxxxxx
# Delete SG
aws ec2 delete-security-group --group-id sg-xxxxxxxx
# Delete subnet
aws ec2 delete-subnet --subnet-id subnet-xxxxxxxx
# Delete IGW
aws ec2 detach-internet-gateway --internet-gateway-id igw-xxxxxxxx --vpc-id vpc-xxxxxxxx
aws ec2 delete-internet-gateway --internet-gateway-id igw-xxxxxxxx
# Delete route table
aws ec2 delete-route-table --route-table-id rtb-xxxxxxxx
# Delete VPC
aws ec2 delete-vpc --vpc-id vpc-xxxxxxxx
```

---

## Summary

- **VPC**: Defines the private network.
- **Subnet**: Public subnet for EC2.
- **IGW**: Enables internet access.
- **Route Table**: Sends traffic to IGW.
- **NACL**: Subnet-level firewall (deny your IP, allow others).
- **SG**: Instance-level firewall (HTTP from all, SSH from your IP).
- **EC2**: Public instance with nginx and SSH/HTTP access.
- **Verification**: Use browser for HTTP, SSH for shell access.
