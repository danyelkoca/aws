# WORM (Write Once Read Many) S3 Bucket Guide

## Create WORM-Enabled Bucket

```bash
aws s3api create-bucket \
  --bucket your-worm-bucket-name \
  --region ap-northeast-1 \
  --object-lock-enabled-for-bucket \
  --create-bucket-configuration LocationConstraint=ap-northeast-1
```

Enable versioning:

```bash
aws s3api put-bucket-versioning \
  --bucket your-worm-bucket-name \
  --versioning-configuration Status=Enabled
```

Apply default object lock policy:

```bash
aws s3api put-object-lock-configuration \
  --bucket your-worm-bucket-name \
  --object-lock-configuration '{
    "ObjectLockEnabled": "Enabled",
    "Rule": {
      "DefaultRetention": {
        "Mode": "GOVERNANCE",
        "Days": 365
      }
    }
  }'
```

## Upload Object with Lock

```bash
aws s3api put-object \
  --bucket your-worm-bucket-name \
  --key hey.txt \
  --body hey.txt \
  --object-lock-mode GOVERNANCE \
  --object-lock-retain-until-date $(date -d "+365 days" --utc +%Y-%m-%dT%H:%M:%SZ)
```

**Sample Response:**
```json
{
  "ETag": "\"12f7adab78f9cf87a161ade5e24142d7\"",
  "ChecksumCRC64NVME": "adtDA44GZgg=",
  "ChecksumType": "FULL_OBJECT",
  "ServerSideEncryption": "AES256",
  "VersionId": "LBZqjpeaL5hlCVtsSoEq_FJ4tBtYYkwZ"
}
```

## Why Not Use `cp` or Simple `put-object`?

Object Lock default policies **only apply** when objects are uploaded with the proper headers:

- `--object-lock-mode`
- `--object-lock-retain-until-date`

Without them, default retention is **ignored**. Bucket-level settings act as templates, not enforcement.

## Verify Retention

```bash
aws s3api get-object-retention \
  --bucket your-worm-bucket-name \
  --key hey.txt
```

**Sample Output:**
```json
{
  "Retention": {
    "Mode": "GOVERNANCE",
    "RetainUntilDate": "2026-05-04T07:36:53+00:00"
  }
}
```

## Deletion Behavior

### As Admin (Full Permissions)

```bash
aws s3 rm s3://your-worm-bucket-name/hey.txt
```

This will succeed if the user has `s3:BypassGovernanceRetention` and `s3:DeleteObject` permissions.

### As Limited User (No Bypass)

```bash
AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... AWS_DEFAULT_REGION=ap-northeast-1 \
aws s3 rm s3://your-worm-bucket-name/hey.txt
```

**Expected Output:**
```
delete failed: s3://your-worm-bucket-name/hey.txt
An error occurred (AccessDenied) when calling the DeleteObject operation:
User is not authorized to perform: s3:DeleteObject
```

This simulates WORM enforcement in real environments.