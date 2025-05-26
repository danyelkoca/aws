## AWS EC2 Key Pairs

### What Are Key Pairs?

Key pairs are used to securely connect to EC2 instances via SSH. Each key pair consists of a public key (stored by AWS) and a private key (downloaded by the user as a `.pem` file). The private key is used when issuing SSH commands.

---

### How to Create a Key Pair

You can create a key pair using the AWS CLI:

```bash
aws ec2 create-key-pair --key-name MyKey --query 'KeyMaterial' --output text > path/to/keypair/pem/file
chmod 400 path/to/keypair/pem/file
```

This creates a key named `MyKey` and saves the private key to `path/to/keypair/pem/file`.

> Important: You cannot retrieve the private key again after creation. Store it securely.

---

### Key Pair in the AWS Console

To view existing key pairs in the AWS Console:

1. Open the **EC2 Dashboard**
2. In the sidebar, go to **Network & Security > Key Pairs**
3. You will see all existing key pairs and their names

---

### How It’s Used in Terraform

In this project, the consumer EC2 instance uses a key pair for SSH access. You must ensure the key exists in AWS (Console or CLI) and then reference it in Terraform using the `key_name` argument.

Example:

```hcl
key_name = "MainKey"
```

You should have a corresponding `path/to/keypair/pem/file` file locally for SSH access:

```bash
ssh -i path/to/keypair/pem/file ec2-user@<public-ip>
```

---

### Notes

- Use `chmod 400` to secure your `.pem` file before using it
- Key pairs are **region-specific**
- Deleting a key from AWS does **not** remove SSH access from existing instances
