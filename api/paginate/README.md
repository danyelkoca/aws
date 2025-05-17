# AWS Pagination Example

This guide demonstrates how to paginate results using AWS CLI, specifically for EC2 subnets.

## Step 1: List All Subnets (Full Response)

```sh
aws ec2 describe-subnets
```

This returns the complete details for all subnets.

## Step 2: Get Only Subnet IDs

```sh
aws ec2 describe-subnets --query "Subnets[].SubnetId" --output json
```

### Example output:

```json
["<subnet-id-1>", "<subnet-id-2>", "<subnet-id-3>"]
```

## Step 3: Limit Results to 1 Item (Triggers Pagination)

```sh
aws ec2 describe-subnets --query "Subnets[].SubnetId" --output json --max-items 1
```

### Example output:

```json
["<subnet-id-1>"]
```

## Step 4: Get the NextToken (for Pagination)

```sh
aws ec2 describe-subnets --max-items 1 --query "NextToken" --output json
```

This retrieves the token to fetch the next set of results.

### Example output:

```json
"eyJOZXh0VG9rZW4iOiBudWxsLCAiYm90b190cnVuY2F0ZV9hbW91bnQiOiAxfQ=="
```

## Step 5: Use NextToken to Get Next Page

```sh
aws ec2 describe-subnets --max-items 1 --starting-token "eyJOZXh0VG9rZW4iOiBudWxsLCAiYm90b190cnVuY2F0ZV9hbW91bnQiOiAxfQ==" --query "Subnets[].SubnetId" --output json
```

### Example output:

```json
["<subnet-id-2>"]
```

## Step 6: Validate Pagination Worked

```sh
aws ec2 describe-subnets --query "Subnets[].SubnetId" --output json --max-items 2
```

### Example output:

```json
["<subnet-id-1>", "<subnet-id-2>"]
```

This confirms that the token successfully advanced to the next item.
