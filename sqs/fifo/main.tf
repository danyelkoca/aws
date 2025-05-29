provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_sqs_queue" "fifo_queue" {
  name                        = "test-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = 30
  message_retention_seconds   = 86400
}

output "send_message_1" {
  value = <<-EOT
aws sqs send-message \
  --queue-url ${aws_sqs_queue.fifo_queue.id} \
  --message-body '{"id": 1, "message": "First message"}' \
  --message-group-id "test-group" \
  --message-deduplication-id "msg1" \
  --region ap-northeast-1
EOT
}

output "send_message_2" {
  value = <<-EOT
aws sqs send-message \
  --queue-url ${aws_sqs_queue.fifo_queue.id} \
  --message-body '{"id": 2, "message": "Second message"}' \
  --message-group-id "test-group" \
  --message-deduplication-id "msg2" \
  --region ap-northeast-1
EOT
}

output "send_message_3" {
  value = <<-EOT
aws sqs send-message \
  --queue-url ${aws_sqs_queue.fifo_queue.id} \
  --message-body '{"id": 3, "message": "Third message"}' \
  --message-group-id "test-group" \
  --message-deduplication-id "msg3" \
  --region ap-northeast-1
EOT
}

output "receive_messages" {
  value = <<-EOT
aws sqs receive-message \
  --queue-url ${aws_sqs_queue.fifo_queue.id} \
  --max-number-of-messages 10 \
  --region ap-northeast-1
EOT
}
