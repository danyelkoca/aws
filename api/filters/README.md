# Using Filters in AWS CLI (EC2 Subnet Examples)

## Step 1: Retrieve All Subnets

```bash
# List all subnets with their ID, state, and availability zone
aws ec2 describe-subnets \
  --query "Subnets[].[SubnetId,State,AvailabilityZone]" \
  --output table
```

## Step 2: Retrieve Subnets Filtered by Availability Zone

```bash
# List only subnets in the 'ap-northeast-1a' availability zone
aws ec2 describe-subnets \
  --filters "Name=availability-zone,Values=ap-northeast-1a" \
  --query "Subnets[].[SubnetId,State,AvailabilityZone]" \
  --output table
```

This helps reduce the output size and improve response time.
