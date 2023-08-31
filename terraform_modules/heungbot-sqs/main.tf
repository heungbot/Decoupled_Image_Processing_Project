# main queue
resource "aws_sqs_queue" "main" {
  name                       = var.SQS_NAME
  delay_seconds              = var.DELAY_SECONDS # 전송 지연 0
  max_message_size           = var.MAX_MESSAGE_SIZE
  message_retention_seconds  = var.MESSAGE_RETENTION_SECONDS # 메시지 보존 기간(최대 4일)
  receive_wait_time_seconds  = var.WAIT_TIME_SECONDS         # 메시지 수신 대기시간(최대 20초) - long pollicy을 위한 시간 의미.
  visibility_timeout_seconds = var.VISIBILITY_TIMEOUT_SECONDS
  sqs_managed_sse_enabled    = true

  # DEAD LETTER QUEUE

  # visibility_timeout_seconds 동안 처리하지 못하는 message 발생
  # 메시지는 다시 sqs 대기열로 복귀 -> consumer가 메시지 읽다가 오류 발생 및 visibility_timeout_seconds 초과하는 경우 발생
  # 해당 과정을 몇 번 반복하면 DLQ(Dead Letter Queue)로 리드라이브.
  # DLQ : 주로 디버깅할 때 사용. 일정 시점 지나면 역시 만료되어 삭제되기 때문에 보관 기간을 높게 잡는 것이 좋음.

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn,
    maxReceiveCount     = var.TO_DEAD_LETTER_QUEUE_RECEIVE_COUNT
  })

  tags = {
    Name = "${var.SQS_NAME}"
  }
}


# dead letter queue
resource "aws_sqs_queue" "dlq" {
  name                       = "${var.SQS_NAME}-dlq"
  delay_seconds              = var.DELAY_SECONDS
  max_message_size           = var.MAX_MESSAGE_SIZE
  message_retention_seconds  = var.MESSAGE_RETENTION_SECONDS
  receive_wait_time_seconds  = var.WAIT_TIME_SECONDS
  visibility_timeout_seconds = var.VISIBILITY_TIMEOUT_SECONDS
  sqs_managed_sse_enabled    = true

}