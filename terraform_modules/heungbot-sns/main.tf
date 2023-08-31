resource "aws_sns_topic" "main" {
  name = var.SNS_TOPIC_NAME

  tags = {
    Name = "${var.SNS_TOPIC_NAME}"
  }
}