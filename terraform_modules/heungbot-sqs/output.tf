output "MAIN_SQS_URL" {
  value = aws_sqs_queue.main.id
}

output "MAIN_SQS_ARN" {
  value = aws_sqs_queue.main.arn
}

output "MAIN_SQS_NAME" {
  value = aws_sqs_queue.main.name
}

output "DLQ_SQS_URL" {
  value = aws_sqs_queue.dlq.id
}

output "DLQ_SQS_ARN" {
  value = aws_sqs_queue.dlq.arn
}

output "DLQ_SQS_NAME" {
  value = aws_sqs_queue.dlq.name
}