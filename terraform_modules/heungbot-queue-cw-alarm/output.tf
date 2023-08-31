output "MAIN_ALARM_ARN" {
  value = aws_cloudwatch_metric_alarm.main.arn
}

output "DLQ_ALARM_ARN" {
  value = aws_cloudwatch_metric_alarm.deadletter_alarm.arn
}