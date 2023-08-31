# sns resource based policy : should allow s3 bucket's publish message permission
resource "aws_sns_topic_policy" "sns_policy" {
  arn    = var.TOPIC_ARN
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

# s3, cloudwatch should publish message
data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "AllowS3Publish"

  statement {
    sid    = "AllowS3Publish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = [
      "sns:Subscribe",
      "sns:Publish"
    ]

    resources = [
      "${var.TOPIC_ARN}"
    ]

    condition {
      test     = "ArnEquals"
      variable = "AWS:SourceArn"

      values = [
        "${var.BUCKET_ARN}"
      ]
    }
  }

  statement {
    sid    = "AllowCloudWatchPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    actions = [
      "sns:Subscribe",
      "sns:Publish"
    ]

    resources = [
      "${var.TOPIC_ARN}"
    ]
  }
}

# main queue resource based policy : should allow SendMessage for sns topic
data "aws_iam_policy_document" "queue_policy" {
  policy_id = "AllowPublishMessageFromSNS"
  version   = "2012-10-17"

  statement {
    actions = ["sqs:SendMessage"]

    effect = "Allow"

    resources = ["${var.MAIN_SQS_ARN}"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = ["${var.TOPIC_ARN}"]
    }
  }
}

resource "aws_sqs_queue_policy" "attach" {
  queue_url = var.MAIN_SQS_URL
  policy    = data.aws_iam_policy_document.queue_policy.json
}



# dead letter queue resource based policy
data "aws_iam_policy_document" "dlp_policy" {
  version = "2012-10-17"

  statement {
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:StartMessageMoveTask",
      "sqs:ListMessageMoveTasks",
      "sqs:CancelMessageMoveTask",
    ]

    resources = ["${var.DLQ_SQS_ARN}"]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = ["${var.MAIN_SQS_ARN}"]
    }
  }

  statement {
    effect = "Allow"

    actions = ["sqs:SendMessage"]

    resources = ["${var.MAIN_SQS_ARN}"]
  }
}

resource "aws_sqs_queue_policy" "dlq_attach" {
  queue_url = var.DLQ_SQS_URL
  policy    = data.aws_iam_policy_document.dlp_policy.json
}