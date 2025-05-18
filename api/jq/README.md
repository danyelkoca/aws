```bash
# Print the entire JSON response
aws ec2 describe-subnets | jq .

# Print the value of the Subnets property (array)
aws ec2 describe-subnets | jq .Subnets

# Error: missing dot for root object
# aws ec2 describe-subnets | jq Subnets

# Access each item in the Subnets array
aws ec2 describe-subnets | jq '.Subnets[]'

# Get AvailabilityZone from each subnet
aws ec2 describe-subnets | jq '.Subnets[] | .AvailabilityZone'

# Incorrect optional chaining; not supported by jq
# aws ec2 describe-subnets | jq .Subnets?.AvailabilityZone?

# Access AvailabilityZone of all subnets
aws ec2 describe-subnets | jq '.Subnets[] | .AvailabilityZone'

# Access AvailabilityZone of the second subnet (index 1)
aws ec2 describe-subnets | jq '.Subnets[1] | .AvailabilityZone'

# Slice: get subnets at index 1 and 2
aws ec2 describe-subnets | jq '.Subnets[1:2]'

# Slice returns array, then flatten and access AvailabilityZone
aws ec2 describe-subnets | jq '.Subnets[1:2][] | .AvailabilityZone'

# Multiple indices (1 and 2), return the subnets
aws ec2 describe-subnets | jq '.Subnets[1,2]'

# Multiple indices, extract AvailabilityZone from each
aws ec2 describe-subnets | jq '.Subnets[1,2] | .AvailabilityZone'

# Combine AvailabilityZone and VpcId from one subnet (index 1)
aws ec2 describe-subnets | jq '.Subnets[1] | {az: .AvailabilityZone, vpc: .VpcId}'

# Combine fields from multiple subnets using map expression
aws ec2 describe-subnets | jq '[.Subnets[1,2][] | {az: .AvailabilityZone, vpc: .VpcId}]'

# Incorrect: dot chaining does not work after pipe
# aws ec2 describe-subnets | jq .Subnets[1].AvailabilityZone|.Subnets[1].VpcId

# Correct usage with pipe and multiple outputs
aws ec2 describe-subnets | jq '.Subnets[] | .AvailabilityZone'

# Equivalent to above (double quotes okay)
aws ec2 describe-subnets | jq ".Subnets[] | .AvailabilityZone"

# Output multiple fields from each subnet
aws ec2 describe-subnets | jq '.Subnets[] | {az: .AvailabilityZone, vpc: .VpcId}'

# Incorrect: Subnets[].X cannot be directly inside object; must iterate first
# aws ec2 describe-subnets | jq '{cidr: Subnets[].AvailabilityZone, id: Subnets[].AvailabilityZone }'

# Object with specific fields from one subnet
aws ec2 describe-subnets | jq '{cidr: .Subnets[0].AvailabilityZone, id: .Subnets[0].VpcId }'

# Incorrect use of array access inside object
# aws ec2 describe-subnets | jq '{cidr: .Subnets[0,1].AvailabilityZone, id: .Subnets[0,1].VpcId }'

# Correct extraction using pipe
aws ec2 describe-subnets | jq '.Subnets[0,1] | {AvailabilityZone, VpcId}'

# Rename fields while extracting
aws ec2 describe-subnets | jq '.Subnets[0,1] | {cidr: .AvailabilityZone, id: .VpcId}'

# Construct JSON object from shell variables
export USERNAME='<your-username>'
export PASSWORD='<your-password>'

# Create JSON object with user and password
jq --null-input \
  --arg user "$USERNAME" \
  --arg password "$PASSWORD" \
  '{"user": $user, "password": $password}'

# Write credentials to a file
jq --null-input \
  --arg user "$USERNAME" \
  --arg password "$PASSWORD" \
  '{"user": $user, "password": $password}' > creds.json

# View the created JSON file
cat creds.json
```
