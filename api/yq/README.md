```bash
brew install yq

aws ec2 describe-subnets | jq .
aws ec2 describe-subnets | yq . # returns text with color
aws ec2 describe-subnets | yq -pjson . # returns yaml by parsing json
aws ec2 describe-subnets | yq -pjson -oy # same as above
aws ec2 describe-subnets | yq -pjson '.Subnets[].AvailabilityZone' -oy # returns yaml of availability zones array

```
