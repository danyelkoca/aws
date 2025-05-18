

#!/bin/bash

# Load environment variables
source .env

echo "Starting deletion of AWS VPC resources..."

# Disassociate route table
echo "Disassociating route table..."
aws ec2 disassociate-route-table --association-id $ASSOC_ID

# Delete route table
echo "Deleting route table..."
aws ec2 delete-route-table --route-table-id $RTB_ID

# Detach internet gateway
echo "Detaching internet gateway..."
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

# Delete internet gateway
echo "Deleting internet gateway..."
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# Delete subnet
echo "Deleting subnet..."
aws ec2 delete-subnet --subnet-id $SUBNET_ID

# Delete VPC
echo "Deleting VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID

echo "Deletion complete."