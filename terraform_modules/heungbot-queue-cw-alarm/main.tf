# queue cloudwatch alarm
resource "aws_cloudwatch_metric_alarm" "main" {
  alarm_name          = "${var.SQS_NAME}-flood-alarm"
  alarm_description   = "main queue alarm. send alarm to sns"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2                                    # 5분 간의 2번의 검사 평가를 진행
  metric_name         = "ApproximateNumberOfMessagesVisible" # 현재 queue에서 처리되지 않은(visible) 대기중인 메시지의 근사치
  # cf NumberOfMessageSent : 큐로 보내진 메시지의 총 수
  namespace          = "AWS/SQS"
  period             = 300 # 5분간의 평가 진행
  statistic          = "Average"
  threshold          = var.MAIN_ALARM_THRESHOLD # 경계치 = 20
  treat_missing_data = "notBreaching"
  alarm_actions      = [var.TOPIC_ARN]
  dimensions = {
    "QueueName" = "${var.SQS_NAME}"
  }

  tags = {
    Name = "${var.SQS_NAME}-alarm"
  }
}

# dlq alarm
resource "aws_cloudwatch_metric_alarm" "deadletter_alarm" {
  alarm_name          = "${var.DLQ_NAME}-not-empty-alarm"
  alarm_description   = "dlq alarm. send alarm to sns"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = var.DLQ_ALARM_THRESHOLD # 경게치 = 50
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.TOPIC_ARN]
  dimensions = {
    "QueueName" = "${var.DLQ_NAME}"
  }
  tags = {
    Name = "${var.DLQ_NAME}-alarm"
  }
}