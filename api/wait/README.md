# Launch an EC2 Instance with Amazon Linux 2023 (Tokyo Region)

## Step 1: Get the Latest Amazon Linux 2023 AMI ID

```bash
# Fetch the latest Amazon Linux 2023 AMI ID in ap-northeast-1 (Tokyo)
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023*-x86_64" \
  --region ap-northeast-1 \
  --query "Images | sort_by(@, &CreationDate) | [-1].[ImageId, Name, CreationDate]" \
  --output table
```

### Sample Output

```table
----------------------------------------------------
|                  DescribeImages                  |
+--------------------------------------------------+
|  <ami-id>                                        |
|  al2023-ami-2023.7.20250512.0-kernel-6.1-x86_64  |
|  2025-05-09T22:50:14.000Z                        |
+--------------------------------------------------+
```

Pick up the `<ami-id>` for the next step.

## Step 2: Launch an EC2 Instance

```bash
# Launch an EC2 instance using the specified AMI
aws ec2 run-instances \
  --image-id <ami-id> \
  --instance-type t2.micro
```

### Sample Output (Truncated for Clarity)

```json
{
  "Instances": [
    {
      "InstanceId": "<instance-id>",
      "ImageId": "<ami-id>",
      "InstanceType": "t2.micro",
      "PrivateIpAddress": "172.31.10.25",
      "SubnetId": "<subnet-id>",
      "VpcId": "<vpc-id>",
      "SecurityGroups": [
        {
          "GroupId": "<security-group-id>",
          "GroupName": "default"
        }
      ],
      "State": {
        "Code": 0,
        "Name": "pending"
      }
    }
  ]
}
```

## Step 3: Wait for the EC2 Instance to Reach 'Running' State

```bash
# Wait until the EC2 instance is in the 'running' state
aws ec2 wait instance-running --instance-ids <instance-id>
```

Note: This command will not output anything until the instance is running.

## Step 4: Stop the EC2 Instance

```bash
# Stop the EC2 instance
aws ec2 stop-instances --instance-ids <instance-id>
```

## Step 5: Terminate the EC2 Instance

```bash
# Terminate the EC2 instance permanently
aws ec2 terminate-instances --instance-ids <instance-id>
```
