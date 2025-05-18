# Chaining AWS CLI Commands

## Chaining with Environment Variables

```bash
# Store the first subnet ID in a variable
export SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=availability-zone,Values=ap-northeast-1a" \
  --query "Subnets[0].SubnetId" \
  --output text)

# Display the stored subnet ID
echo "Subnet ID: $SUBNET_ID"
```

## Use the Environment Variable in a Command

```bash
# Use the saved SUBNET_ID to describe its details
aws ec2 describe-subnets \
  --subnet-ids $SUBNET_ID \
  --query "Subnets[].[SubnetId,State,AvailabilityZone]" \
  --output json
```

### Example Output

```json
[["<subnet-id>", "available", "ap-northeast-1a"]]
```

---

## Chaining with xargs

```bash
# Chain commands using xargs to pass the first subnet ID as an argument
aws ec2 describe-subnets \
  --filters "Name=availability-zone,Values=ap-northeast-1a" \
  --query "Subnets[0].SubnetId" \
  --output text | \
xargs -I {} aws ec2 describe-subnets \
  --subnet-ids {} \
  --query "Subnets[].[SubnetId,State,AvailabilityZone]" \
  --output json
```

In this example:

- The output of the first command (a subnet ID) is passed as an argument to the second command using `xargs`.
- The `-I {}` flag replaces `{}` with the value from the first command.
