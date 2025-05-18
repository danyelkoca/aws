# AWS VPC Setup Guide

This guide demonstrates how to create a basic VPC setup in AWS using the CLI. The setup includes a VPC, subnet, Internet Gateway, route table, and a default route to enable public internet access.

---

## Step 1: Create a VPC

Creates a new VPC with a /16 CIDR block.

```bash
aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=MyVPC}]'
```

### Example Output

```json
{
  "Vpc": {
    "VpcId": "<vpc-id>",
    "CidrBlock": "10.0.0.0/16",
    "State": "pending",
    "Tags": [{ "Key": "Name", "Value": "MyVPC" }]
  }
}
```

---

## Step 2: Create a Subnet

Creates a subnet within the VPC using a /24 CIDR block.

```bash
aws ec2 create-subnet \
  --vpc-id <vpc-id> \
  --cidr-block 10.0.1.0/24 \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=MySubnet}]'
```

### Example Output

```json
{
  "Subnet": {
    "SubnetId": "<subnet-id>",
    "VpcId": "<vpc-id>",
    "CidrBlock": "10.0.1.0/24",
    "AvailabilityZone": "ap-northeast-1c",
    "MapPublicIpOnLaunch": false,
    "Tags": [{ "Key": "Name", "Value": "MySubnet" }]
  }
}
```

---

## Step 3: Create an Internet Gateway (IGW)

Creates a gateway for internet-bound traffic.

```bash
aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=MyIGW}]'
```

### Example Output

```json
{
  "InternetGateway": {
    "InternetGatewayId": "<igw-id>",
    "Tags": [{ "Key": "Name", "Value": "MyIGW" }]
  }
}
```

---

## Step 4: Attach IGW to VPC

Connects the IGW to your VPC to enable routing to the internet.

```bash
aws ec2 attach-internet-gateway \
  --vpc-id <vpc-id> \
  --internet-gateway-id <igw-id>
```

---

## Step 5: Verify IGW Attachment

Confirms the IGW is attached to the correct VPC.

```bash
aws ec2 describe-internet-gateways \
  --query "InternetGateways[*].{ID:InternetGatewayId,VPC:Attachments[0].VpcId}"
```

### Example Output

```json
[
  {
    "ID": "<igw-id>",
    "VPC": "<vpc-id>"
  }
]
```

---

## Step 6: Create a Route Table

Creates a route table for your VPC.

```bash
aws ec2 create-route-table \
  --vpc-id <vpc-id> \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=MyRouteTable}]'
```

### Example Output

```json
{
  "RouteTable": {
    "RouteTableId": "<rtb-id>",
    "Routes": [{ "DestinationCidrBlock": "10.0.0.0/16", "GatewayId": "local" }],
    "Tags": [{ "Key": "Name", "Value": "MyRouteTable" }]
  }
}
```

---

## Step 7: Create a Default Route

Adds a route to forward all internet-bound traffic to the IGW.

```bash
aws ec2 create-route \
  --route-table-id <rtb-id> \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id <igw-id>
```

### Example Output

```json
{
  "Return": true
}
```

---

## What Does 0.0.0.0/0 Do?

This default route sends all non-local traffic to the internet through the IGW. Without it, your instances cannot access or be accessed from the internet.

---

## Step 8: Associate Route Table with Subnet

Applies the route table to the subnet.

```bash
aws ec2 associate-route-table \
  --subnet-id <subnet-id> \
  --route-table-id <rtb-id>
```

### Example Output

```json
{
  "AssociationId": "<association-id>",
  "AssociationState": { "State": "associated" }
}
```

---

## Step 9: Clean Up Resources

Deletes all resources in reverse order.

```bash
aws ec2 disassociate-route-table --association-id <association-id>

aws ec2 delete-route-table --route-table-id <rtb-id>

aws ec2 detach-internet-gateway --internet-gateway-id <igw-id> --vpc-id <vpc-id>

aws ec2 delete-internet-gateway --internet-gateway-id <igw-id>

aws ec2 delete-subnet --subnet-id <subnet-id>

aws ec2 delete-vpc --vpc-id <vpc-id>
```
