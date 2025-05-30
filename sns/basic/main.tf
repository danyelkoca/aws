provider "aws" {
  region = "ap-northeast-1"
}

# Create an SNS topic
resource "aws_sns_topic" "notify_me" {
  name = "notify-me"
}

# Create an email subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.notify_me.arn
  protocol  = "email"
  endpoint  = "youremailaddress@gmail.com" # You'll need to replace this
}

output "publish_command" {
  value = "aws sns publish --topic-arn ${aws_sns_topic.notify_me.arn} --message 'Hello from SNS!' --region ap-northeast-1"
}
