# Amazon S3 Object Lock & WORM Cookbook

This guide shows how to create **Write Once Read Many (WORM)** buckets in S3, apply **Object Lock** (Governance or Compliance), add **Legal Hold**, and clean up when finished.

---

## 1 — Concept Primer

| Feature            | Purpose | Deletion Rules |
|--------------------|---------|----------------|
| **Governance**     | Prevents edits/deletes *unless* the caller has `s3:BypassGovernanceRetention`. | Admins with that permission can override. |
| **Compliance**     | Absolute protection until the retention date expires. | Nobody can delete or shorten retention. |
| **Legal Hold**     | Temporary block independent of retention. | Turn OFF before delete. |
| **Delete Markers** | “Tombstones” created by `s3 rm` in versioned buckets. | Delete them to reveal older versions. |

Retention applies **only** to objects uploaded with the Object‑Lock headers.

---

## 2 — Create a WORM Bucket

```bash
# 2‑1 Create bucket WITH Object Lock enabled
aws s3api create-bucket \
  --bucket my-worm-bucket \
  --region ap-northeast-1 \
  --object-lock-enabled-for-bucket \
  --create-bucket-configuration LocationConstraint=ap-northeast-1

# 2‑2 Turn on versioning (mandatory)
aws s3api put-bucket-versioning \
  --bucket my-worm-bucket \
  --versioning-configuration Status=Enabled
```

### Optional default retention

```bash
aws s3api put-object-lock-configuration \
  --bucket my-worm-bucket \
  --object-lock-configuration '{
    "ObjectLockEnabled":"Enabled",
    "Rule":{ "DefaultRetention":{ "Mode":"GOVERNANCE", "Days":365 } }
  }'
```

---

## 3 — Upload With Retention

```bash
date_in_year=$(date -d "+365 days" --utc +%Y-%m-%dT%H:%M:%SZ)

aws s3api put-object \
  --bucket my-worm-bucket \
  --key report.txt \
  --body report.txt \
  --object-lock-mode GOVERNANCE \
  --object-lock-retain-until-date "$date_in_year"
```

Verify:

```bash
aws s3api get-object-retention --bucket my-worm-bucket --key report.txt
```

---

## 4 — Deletion Scenarios

### 4‑1 Admin with bypass

```bash
aws s3api delete-object \
  --bucket my-worm-bucket \
  --key report.txt \
  --version-id <VersionId> \
  --bypass-governance-retention   # Works only in GOVERNANCE
```

### 4‑2 Limited user

```bash
aws s3 rm s3://my-worm-bucket/report.txt   # → AccessDenied
```

### 4‑3 Compliance mode

Set `--object-lock-mode COMPLIANCE`; **no one** can delete before expiry.

---

## 5 — Legal Hold Walk‑Through

```bash
aws s3api put-object-legal-hold \
  --bucket my-worm-bucket \
  --key report.txt \
  --version-id <VersionId> \
  --legal-hold Status=ON
```

Turn OFF and delete:

```bash
aws s3api put-object-legal-hold \
  --bucket my-worm-bucket \
  --key report.txt \
  --version-id <VersionId> \
  --legal-hold Status=OFF

aws s3api delete-object \
  --bucket my-worm-bucket \
  --key report.txt \
  --version-id <VersionId> \
  --bypass-governance-retention
```

---

## 6 — Full Cleanup Script

```bash
# Delete all object versions (requires bypass permission)
aws s3api list-object-versions --bucket my-worm-bucket \
  --query 'Versions[].{Key:Key,VersionId:VersionId}' --output text |
  awk '{print $1, $2}' |
  while read k v; do
    aws s3api delete-object --bucket my-worm-bucket --key "$k" --version-id "$v" --bypass-governance-retention
  done

# Delete all delete markers
aws s3api list-object-versions --bucket my-worm-bucket \
  --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output text |
  awk '{print $1, $2}' |
  while read k v; do
    aws s3api delete-object --bucket my-worm-bucket --key "$k" --version-id "$v"
  done

# Finally remove bucket
aws s3 rb s3://my-worm-bucket
```

---

## 7 — Cheat Sheet

*Enable Object Lock → Enable Versioning → Upload with Lock headers → Verify → Manage Legal Hold.*

Use **Governance** when you need an emergency‑override path; use **Compliance** for absolute immutability.

---