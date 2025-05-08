# S3 MFA Delete Walkthrough (Full Setup with Root Credentials)

## 1. Introduction

This guide explains the ownership and permission model for AWS S3 buckets, focusing on enabling versioning and MFA (Multi-Factor Authentication) delete. It covers why MFA delete can only be enabled by the root user using the AWS CLI, and walks through the necessary steps to enable it securely.

---

## 2. Create S3 Bucket

Create a new S3 bucket using the AWS CLI:

```sh
aws s3 mb s3://<BUCKET_NAME>
```

---

## 3. Check Caller Identity

Verify the current IAM user or root user you are authenticated as:

```sh
aws sts get-caller-identity
```

Example output:

```json
{
  "UserId": "AIDAEXAMPLEUSERID",
  "Account": "<ACCOUNT_ID>",
  "Arn": "arn:aws:iam::<ACCOUNT_ID>:user/<USER_NAME>"
}
```

> Note: This shows the IAM user currently using the CLI, not the root user. Credentials used here are for an IAM user, which is a best practice instead of using root credentials directly.

---

## 4. Verify Bucket Ownership

Check the owner of the bucket with this command:

```sh
aws s3api get-bucket-acl --bucket <BUCKET_NAME>
```

Example output:

```json
{
  "Owner": {
    "DisplayName": "<DISPLAY_NAME>",
    "ID": "<OWNER_CANONICAL_ID>"
  },
  "Grants": [
    {
      "Grantee": {
        "DisplayName": "<DISPLAY_NAME>",
        "ID": "<OWNER_CANONICAL_ID>",
        "Type": "CanonicalUser"
      },
      "Permission": "FULL_CONTROL"
    }
  ]
}
```

> **Important:** Even though the bucket was created by an IAM user, the bucket ownership belongs to the AWS account root user. S3 buckets are account-level resources.

---

## 5. Enable Versioning vs MFA Delete (Who Can Do What)

- **Versioning**: Can be enabled by any IAM user with appropriate permissions.
- **MFA Delete**: Can only be enabled by the **root user** via the AWS CLI.
- MFA Delete **cannot** be enabled through the AWS Management Console or UI.

---

## 6. Why You Cannot Use AWS Console

If you check your identity in AWS CloudShell or Console:

```sh
aws sts get-caller-identity
```

Example output:

```json
{
  "UserId": "<ACCOUNT_ID>",
  "Account": "<ACCOUNT_ID>",
  "Arn": "arn:aws:iam::<ACCOUNT_ID>:root"
}
```

Even though the ARN ends with `:root`, CloudShell uses temporary DevPay-style credentials which are incompatible with the `--mfa` parameter required for enabling MFA delete.

Attempting to enable MFA delete in CloudShell:

```sh
aws s3api put-bucket-versioning --bucket <BUCKET_NAME> --versioning-configuration Status=Enabled,MFADelete=Enabled --mfa "arn:aws:iam::<ACCOUNT_ID>:mfa/<MFA_DEVICE_NAME> <MFA_CODE>"
```

Results in:

```
An error occurred (InvalidRequest) when calling the PutBucketVersioning operation: DevPay and Mfa are mutually exclusive authorization methods.
```

The AWS Console UI also confirms that MFA Delete settings can only be modified via CLI or API.

---

## 7. Required: CLI and Root Credentials with MFA

To enable MFA delete, you must:

- Use the **root user** credentials (not CloudShell or IAM user).
- Use the AWS CLI.
- Provide the MFA device ARN and the current MFA code.

---

## 8. Generate and Configure Root MFA

1. Sign in to the AWS Console as the root user.
2. Navigate to **My Security Credentials** (top right corner).
3. Under **Multi-Factor Authentication (MFA)**, create a **Virtual MFA Device**.
4. Download the QR code and scan it with an authenticator app like Authy or Google Authenticator.
5. Enter the generated MFA codes to verify and activate the MFA device.

---

## 9. Generate Root Access Keys Temporarily

1. In the AWS Console, go to **IAM > Users > Root User > Security Credentials**.
2. Create a new **Access Key** for the root user.
3. Download and save the credentials securely.

> **Warning:** Root user access keys are not recommended for general use. Use them only temporarily for enabling MFA Delete as a last resort.

---

## 10. Configure AWS CLI with Root Keys

Configure your AWS CLI with the root user access key and secret access key:

```sh
aws configure
```

Enter the following when prompted:

```
AWS Access Key ID [None]: <ROOT_ACCESS_KEY_ID>
AWS Secret Access Key [None]: <ROOT_SECRET_ACCESS_KEY>
Default region name [None]: <REGION>
Default output format [None]: json
```

---

## 11. Enable MFA Delete

Run the following command with the root credentials and MFA information:

```sh
aws s3api put-bucket-versioning \
  --bucket <BUCKET_NAME> \
  --versioning-configuration Status=Enabled,MFADelete=Enabled \
  --mfa "arn:aws:iam::<ACCOUNT_ID>:mfa/<MFA_DEVICE_NAME> <MFA_CODE>"
```

- `<MFA_DEVICE_NAME>`: The name of your MFA device.
- `<MFA_CODE>`: The current MFA code from your authenticator app.

---

## 12. Verify Result

Check the bucket versioning status to confirm MFA Delete is enabled:

```sh
aws s3api get-bucket-versioning --bucket <BUCKET_NAME>
```

Expected output:

```json
{
  "Status": "Enabled",
  "MFADelete": "Enabled"
}
```

---

## 13. Demonstration: Deleting a Versioned Object with MFA Delete Enabled

### Step 1: Upload a file

Create a test file:

```sh
echo 'Hello, World!' > test.txt
```

Upload the file to the bucket:

```sh
aws s3api put-object --bucket <BUCKET_NAME> --key test.txt --body test.txt
```

Example output:

```json
{
  "ETag": "\"bea8252ff4e80f41719ea13cdf007273\"",
  "ChecksumCRC64NVME": "SoXXbx67KpE=",
  "ChecksumType": "FULL_OBJECT",
  "ServerSideEncryption": "AES256",
  "VersionId": "<VERSION_ID>"
}
```

### Step 2: Delete without MFA

Delete the file (this creates a delete marker but does not permanently remove the version):

```sh
aws s3api delete-object --bucket <BUCKET_NAME> --key test.txt
```

This works because the version is still alive and the delete marker is added.

### Step 3: Try deleting version as IAM user

List versions and delete markers:

```json
{
  "Versions": [
    {
      "ETag": "\"bea8252ff4e80f41719ea13cdf007273\"",
      "ChecksumAlgorithm": ["CRC64NVME"],
      "ChecksumType": "FULL_OBJECT",
      "Size": 14,
      "StorageClass": "STANDARD",
      "Key": "test.txt",
      "VersionId": "<VERSION_ID>",
      "IsLatest": false,
      "LastModified": "2025-05-08T06:51:17+00:00",
      "Owner": {
        "DisplayName": "<USER_NAME>",
        "ID": "<OWNER_CANONICAL_ID>"
      }
    }
  ],
  "DeleteMarkers": [
    {
      "Owner": {
        "DisplayName": "<USER_NAME>",
        "ID": "<OWNER_CANONICAL_ID>"
      },
      "Key": "test.txt",
      "VersionId": "<DELETE_MARKER_VERSION_ID>",
      "IsLatest": true,
      "LastModified": "2025-05-08T06:51:53+00:00"
    }
  ],
  "RequestCharged": null,
  "Prefix": ""
}
```

Attempt to delete a specific version as IAM user without MFA:

```sh
aws s3api delete-object --bucket <BUCKET_NAME> --key test.txt --version-id <VERSION_ID>
```

Output:

```
An error occurred (AccessDenied) when calling the DeleteObject operation: Mfa Authentication must be used for this request
```

Attempt to delete the version as IAM user with MFA:

```sh
aws s3api delete-object --bucket <BUCKET_NAME> --key test.txt --version-id <VERSION_ID> --mfa "arn:aws:iam::<ACCOUNT_ID>:mfa/<MFA_DEVICE_NAME> <MFA_CODE>"
```

Output:

```
An error occurred (AccessDenied) when calling the DeleteObject operation: This operation may only be performed by the bucket owner
```

This happens even though the IAM user has `s3:FullAccess`. This is because:

- Regular Bucket Operations (like creating and deleting buckets) can be performed by IAM users with appropriate permissions.
- MFA Delete Operations (specifically for versioned objects) can only be performed by the bucket owner (root user).
- The error is specifically for MFA delete operations on versioned objects, not for regular bucket operations.

### Step 4: Delete version with root MFA

Attempting to delete the version as root user without MFA:

```sh
aws s3api delete-object --bucket <BUCKET_NAME> --key test.txt --version-id <VERSION_ID>
```

Output:

```
An error occurred (AccessDenied) when calling the DeleteObject operation: Mfa Authentication must be used for this request
```

Delete the version as root user with MFA:

```sh
aws s3api delete-object --bucket <BUCKET_NAME> --key test.txt --version-id <DELETE_MARKER_VERSION_ID> --mfa "arn:aws:iam::<ACCOUNT_ID>:mfa/<MFA_DEVICE_NAME> <MFA_CODE>"
```

Example output:

```json
{
  "VersionId": "<VERSION_ID>"
}
```

### Step 5: Remove delete markers and delete bucket

After deleting all versions and delete markers, the bucket can be removed without MFA:

```sh
aws s3api delete-bucket --bucket <BUCKET_NAME>
```

---

# Summary

- S3 buckets are owned by the AWS account root user.
- IAM users can enable versioning, but only the root user can enable MFA Delete.
- MFA Delete cannot be enabled through the AWS Console or CloudShell due to credential restrictions.
- Use root user credentials with MFA and the AWS CLI to enable MFA Delete securely.
- MFA Delete operations on versioned objects require the root user and MFA authentication.
- Regular bucket operations can be performed by IAM users with appropriate permissions.
