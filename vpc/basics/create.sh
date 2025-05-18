#!/bin/bash

# Step 1: Create VPC
echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=MyVPC}]' \
  --query "Vpc.VpcId" --output text)
echo "VPC created: $VPC_ID"

# Step 2: Create Subnet
echo "Creating Subnet..."
SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=MySubnet}]' \
  --query "Subnet.SubnetId" --output text)
echo "Subnet created: $SUBNET_ID"

# Step 3: Create Internet Gateway
echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=MyIGW}]' \
  --query "InternetGateway.InternetGatewayId" --output text)
echo "Internet Gateway created: $IGW_ID"

# Step 4: Attach Internet Gateway to VPC
echo "Attaching IGW to VPC..."
aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID
echo "IGW attached to VPC."

# Step 5: Create Route Table
echo "Creating Route Table..."
RTB_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=MyRouteTable}]' \
  --query "RouteTable.RouteTableId" --output text)
echo "Route Table created: $RTB_ID"

# Step 6: Create Route to IGW
echo "Creating route to IGW..."
aws ec2 create-route \
  --route-table-id $RTB_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID
echo "Default route to IGW created."

# Step 7: Associate Route Table with Subnet
echo "Associating Route Table with Subnet..."
ASSOC_ID=$(aws ec2 associate-route-table \
  --subnet-id $SUBNET_ID \
  --route-table-id $RTB_ID \
  --query "AssociationId" --output text)
echo "Route Table associated: $ASSOC_ID"

# Step 8: Save IDs to .env file for later use
echo "Saving resource IDs to .env..."
cat <<EOF > .env
VPC_ID=$VPC_ID
SUBNET_ID=$SUBNET_ID
IGW_ID=$IGW_ID
RTB_ID=$RTB_ID
ASSOC_ID=$ASSOC_ID
EOF
echo "Resource IDs saved to .env"