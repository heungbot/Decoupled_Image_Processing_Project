# 01 rekognition lambda
resource "aws_lambda_function" "main" {

  function_name = var.LAMBDA_FUNCTION_NAME
  role          = aws_iam_role.main_role.arn
  filename      = var.LAMBDA_FUNCTION_FILE_PATH # s3가 될 수도 있고, local의 파일이 될 수도 있음.
  handler       = var.LAMBDA_HANDLER_NAME

  runtime = var.LAMBDA_FUNCTION_RUNTIME

  timeout     = var.LAMBDA_TIMEOUT_SEC
  memory_size = var.LAMBDA_MEMORY_SIZE # default = 128. 메모리를 꽤 사용하는 것을 가정하였기에, memory size 증가

  ephemeral_storage {
    size = var.LAMBDA_EPHEMERAL_STORAGE_SIZE # default = 512. supported value = 1024
  }

  environment {
    variables = {
      BUCKET_NAME = "${var.BUCKET_NAME}"
      PREFIX      = "${var.INGEST_PREFIX}"
      SQS_URL     = "${var.MAIN_SQS_URL}"
    }
  }

  tags = {
    Name = "${var.LAMBDA_FUNCTION_NAME}"
  }
}

# lambda role
resource "aws_iam_role" "main_role" {
  name = var.LAMBDA_ROLE_NAME # imageProcessingLambdaRole

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "${var.LAMBDA_ROLE_NAME}"
  }
}

# lambda role policy

data "aws_iam_policy" "lambda_execute_policy" {
  arn = var.LAMBDA_EXECUTE_POLICY_ARN # arn:aws:iam::aws:policy/AWSLambdaExecute
}


resource "aws_iam_policy" "main_policy" {
  name        = "main_policy"
  path        = "/"
  description = "allow s3, sqs, rekognition"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
          "s3-object-lambda:*",
          "sqs:*",
          "rekognition:*",
          "textract:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_execute" { # execute policy attachment
  role       = aws_iam_role.main_role.name
  policy_arn = data.aws_iam_policy.lambda_execute_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_services" { # other service permission attachment
  role       = aws_iam_role.main_role.name
  policy_arn = aws_iam_policy.main_policy.arn
}

# trigger setup
resource "aws_lambda_event_source_mapping" "main-mapping" {
  event_source_arn = var.MAIN_SQS_ARN
  function_name    = aws_lambda_function.main.arn
}

# slack lambda funtion
data "aws_lambda_function" "slack_lambda" {
  function_name = "sns-slack-lambda"
}


