# AWS SNS Basic Example

This example demonstrates a basic setup of Amazon Simple Notification Service (SNS) with email notifications.

## What is SNS?

Amazon SNS (Simple Notification Service) is a fully managed pub/sub messaging service. It enables:

- Decoupled communication between systems
- Fan-out messaging (one message to many receivers)
- Multiple protocols (HTTP/S, Email, SMS, SQS, Lambda, etc.)
- Reliable message delivery with retries

## Architecture

```
[SNS Topic] → [Email Subscription]
```

## Setup Instructions

1. Update `main.tf` with your email address
2. Run Terraform:
   ```bash
   terraform init
   terraform apply
   ```
3. **Important**: Check your email and confirm the subscription
   - AWS will send a confirmation email
   - You must click the confirmation link
   - Messages won't be delivered until confirmed

## Testing

After confirming your email subscription, send a test message:

```bash
# Get the publish command
terraform output -raw publish_command

# Or send directly
aws sns publish \
  --topic-arn $(terraform output -raw topic_arn) \
  --message "Test message" \
  --region ap-northeast-1
```

## Email Subscription Notes

1. **Confirmation Required**

   - Email subscriptions require manual confirmation
   - This is a security measure by AWS
   - Cannot be automated through Terraform

2. **Confirmation Process**

   - Check your email after applying Terraform
   - Look for "AWS Notification - Subscription Confirmation"
   - Click "Confirm subscription" link
   - You'll see a confirmation webpage

3. **Troubleshooting**
   - No confirmation email? Check spam folder
   - Link expired? Rerun `terraform apply`
   - Still having issues? Check AWS SNS console

## Cleanup

To remove all resources:

```bash
terraform destroy
```

Note: Unconfirmed subscriptions will automatically expire after 3 days.
