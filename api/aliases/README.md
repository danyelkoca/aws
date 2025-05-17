# AWS CLI Alias Setup

## Step 1: Create the Alias File

```bash
echo "[toplevel]" > ~/aws/aliases/alias
echo "dsub = ec2 describe-subnets --query \"Subnets[].[SubnetId,State,AvailabilityZone]\" --output table" >> ~/aws/aliases/alias
```

## Step 2: Copy the Alias File to AWS CLI Directory

```bash
cp ~/aws/aliases/alias ~/.aws/cli/alias
```

## Step 3: Verify the Alias File is Copied

```bash
ls -l ~/.aws/cli
cat ~/.aws/cli/alias
```

## Step 4: Use the Alias Command

```bash
aws dsub
```

### Example Output

```table
--------------------------------------------------------------
|                       DescribeSubnets                      |
+---------------------------+------------+-------------------+
|  <subnet-id-1>            |  available |  ap-northeast-1d  |
|  <subnet-id-2>            |  available |  ap-northeast-1c  |
|  <subnet-id-3>            |  available |  ap-northeast-1a  |
+---------------------------+------------+-------------------+
```
