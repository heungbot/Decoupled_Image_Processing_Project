output "slack_lambda_arn" {
  value = data.aws_lambda_function.slack_lambda.arn
}