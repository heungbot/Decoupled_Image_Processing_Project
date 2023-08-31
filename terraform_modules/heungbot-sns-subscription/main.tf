# sns subscription with filter policy "sqs"
resource "aws_sns_topic_subscription" "sns_sqs" {
  topic_arn           = var.TOPIC_ARN
  protocol            = "sqs"
  endpoint            = var.MAIN_SQS_ARN
  filter_policy_scope = "MessageBody" # 
  filter_policy = jsonencode({        # sqs에는 s3 bucket의 alarm만 들어가도록 설정.
    Records = {
      s3 = {
        object = {
          key = [
            {
              prefix = "ingest/"
            }
          ]
        }
      },
      eventName = [
        {
          prefix = "ObjectCreated:"
        }
      ]
    }
  })
}

# sns subscription with filter policy for "lambda"
resource "aws_sns_topic_subscription" "sns_lambda" {
  topic_arn           = var.TOPIC_ARN
  protocol            = "lambda"
  endpoint            = var.SLACK_LAMBDA_ARN
  filter_policy_scope = "MessageBody" # 
  filter_policy = jsonencode({        # sqs에는 s3 bucket의 alarm만 들어가도록 설정.
    AlarmArn = ["${var.DLQ_ALARM_ARN}"]
  })
}