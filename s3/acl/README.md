# S3 Bucket ACL Management Exercise

This guide demonstrates how to manage Access Control Lists (ACLs) for an AWS S3 bucket.

## Bucket Setup

### 1. Create a new bucket
```sh
aws s3api create-bucket \
    --bucket dannykbucket3 \
    --create-bucket-configuration LocationConstraint=ap-northeast-1
```

### 2. Configure public access settings
```sh
aws s3api put-public-access-block \
    --bucket dannykbucket3 \
    --public-access-block-configuration '{
        "BlockPublicAcls": false,
        "IgnorePublicAcls": false,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }'
```

### 3. Verify public access settings
```sh
aws s3api get-public-access-block --bucket dannykbucket3
```

Expected output:
```json
{
        "PublicAccessBlockConfiguration": {
                "BlockPublicAcls": false,
                "IgnorePublicAcls": false,
                "BlockPublicPolicy": true,
                "RestrictPublicBuckets": true
        }
}
```

## Managing Ownership and ACLs

### 1. Set bucket ownership controls
```sh
aws s3api put-bucket-ownership-controls \
    --bucket dannykbucket3 \
    --ownership-controls '{"Rules":[{"ObjectOwnership":"BucketOwnerPreferred"}]}'
```

> After this step, ACLs become editable.

![ACL screenshot](./acl.png)

### 2. Set bucket-level ACL permissions
```sh
aws s3api put-bucket-acl \
    --bucket dannykbucket3 \
    --grant-full-control id=[Your user canonical ID],id=[Recipient's canonical ID]
```

> **Important:** When using put-bucket-acl, it overwrites (not merges) the existing ACL. Always include your own canonical ID to preserve your access.

## Object-Level Access Control

To make files visible to another user, you must grant access at the object level in addition to bucket-level permissions:

```sh
aws s3api put-object \
    --bucket dannykbucket3 \
    --key README.md \
    --body README.md \
    --grant-read id=[Recipient's canonical ID] \
    --grant-full-control id=[Your user canonical ID]
```

### Verifying access

The recipient can verify their access using:

```sh
aws s3api get-object \
    --bucket dannykbucket3 \
    --key README.md \
    ./README.md
```

> **Note:** All files uploaded to the bucket are visible to the bucket owner, but for other users to access files, they need explicit object-level permissions.