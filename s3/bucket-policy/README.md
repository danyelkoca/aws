# Bucket policies

## Crate bucket
aws s3 mb s3://dannykbucket

## Add policy
aws s3api put-bucket-policy \
  --bucket dannykbucket \
  --policy file://policy.json \
  --no-cli-auto-prompt