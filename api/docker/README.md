# AWS CLI in Docker

This guide demonstrates how to use the official AWS CLI image in Docker to run commands and manage AWS services.

---

## Step 1: Check AWS CLI Version

```bash
# Verify the AWS CLI version inside the container
docker run --rm -it amazon/aws-cli --version
```

---

## Step 2: Attempt to List S3 Buckets (Fails Without Credentials)

```bash
# Attempt to list S3 buckets without credentials
docker run --rm -it amazon/aws-cli s3 ls
```

### Expected Output

```text
Unable to locate credentials. You can configure credentials by running "aws configure".
```

---

## Step 3: Provide AWS Credentials via Volume Mount

```bash
# Mount your local AWS credentials directory into the container
docker run --rm -it \
  -v ~/.aws:/root/.aws \
  amazon/aws-cli ec2 describe-subnets \
    --filters "Name=availability-zone,Values=ap-northeast-1a" \
    --query "Subnets[0].SubnetId" \
    --output text
```

This command lists the first subnet ID in the `ap-northeast-1a` availability zone using your local AWS credentials.

---

## Step 4: Delete Docker Image (Optional)

```bash
# Remove the downloaded AWS CLI image from your local system
docker rmi amazon/aws-cli
```
