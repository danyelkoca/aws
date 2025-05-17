# AWS CLI Query Usage Examples

## Key Difference: Filter vs Query

- **Filters**: server-side; limit what data is returned.
- **Query**: client-side; formats or extracts specific parts of the response.

---

## Example 1: Get Subnet States

```bash
# Retrieve the 'State' value of all subnets
aws ec2 describe-subnets --query "Subnets[].State"
```

### Output

```json
["available", "available", "available"]
```

---

## Example 2: Get Subnet ID and Availability Zone (Where State is 'available')

```bash
# Retrieve only subnets that are 'available' and show their Subnet ID and AZ
aws ec2 describe-subnets --query "Subnets[?State=='available'].{ID:SubnetId, AZ:AvailabilityZone}"
```

### Output

```json
[
  {
    "ID": "<subnet-id-1>",
    "AZ": "ap-northeast-1d"
  },
  {
    "ID": "<subnet-id-2>",
    "AZ": "ap-northeast-1c"
  },
  {
    "ID": "<subnet-id-3>",
    "AZ": "ap-northeast-1a"
  }
]
```
