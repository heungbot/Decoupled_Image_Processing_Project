# 1. sqs, sns and s3 service create(because event notification)
# 3. lambda module
module "sqs" {
  source                             = "./heungbot-sqs"
  SQS_NAME                           = "heungbot-image-processing-queue"
  DELAY_SECONDS                      = 0
  MAX_MESSAGE_SIZE                   = 262144 # 256kb
  MESSAGE_RETENTION_SECONDS          = 172800 # 2일
  WAIT_TIME_SECONDS                  = 15
  VISIBILITY_TIMEOUT_SECONDS         = 300
  TO_DEAD_LETTER_QUEUE_RECEIVE_COUNT = 100
}

module "sns" {
  source         = "./heungbot-sns"
  SNS_TOPIC_NAME = "heungbot-image-processing-topic"
  MAIN_SQS_ARN   = module.sqs.MAIN_SQS_ARN
  depends_on     = [module.sqs]
}

module "s3" {
  source        = "./heungbot-s3"
  depends_on    = [module.sns]
  BUCKET_NAME   = "heungbot-image-processing-bucket"
  SOURCE_FOLDER = "ingest/"
  RESULT_FOLDER = "results/"
  TOPIC_ARN     = module.sns.TOPIC_ARN
}

module "resource_based_policy" {
  source       = "./heungbot-resource-based-policy"
  depends_on   = [module.sqs, module.sns, module.s3]
  TOPIC_ARN    = module.sns.TOPIC_ARN
  BUCKET_ARN   = module.s3.BUCKET_ARN
  MAIN_SQS_ARN = module.sqs.MAIN_SQS_ARN
  MAIN_SQS_URL = module.sqs.MAIN_SQS_URL
  DLQ_SQS_ARN  = module.sqs.DLQ_SQS_ARN
  DLQ_SQS_URL  = module.sqs.DLQ_SQS_URL

}

module "cw_alarm" {
  source               = "./heungbot-queue-cw-alarm"
  MAIN_ALARM_THRESHOLD = 1
  DLQ_ALARM_THRESHOLD  = 1
  SQS_NAME             = module.sqs.MAIN_SQS_NAME
  DLQ_NAME             = module.sqs.DLQ_SQS_NAME
  TOPIC_ARN            = module.sns.TOPIC_ARN
}

module "s3_event_notification" {
  source        = "./heungbot-s3-event-notification"
  depends_on    = [module.resource_based_policy] # sns에 s3가 publish할 수 있는 권한이 부여된 후에 notification 생성 가능
  BUCKET_NAME   = module.s3.BUCKET_NAME
  TOPIC_ARN     = module.sns.TOPIC_ARN
  SOURCE_FOLDER = module.s3.SOURCE_FOLDER_NAME

}

module "lambda" {
  source                        = "./heungbot-lambda"
  depends_on                    = [module.resource_based_policy]
  BUCKET_NAME                   = module.s3.BUCKET_NAME
  INGEST_PREFIX                 = module.s3.SOURCE_FOLDER_NAME
  MAIN_SQS_URL                  = module.sqs.MAIN_SQS_URL
  MAIN_SQS_ARN                  = module.sqs.MAIN_SQS_ARN
  LAMBDA_FUNCTION_FILE_PATH     = "../lambda/image_lambda.zip"
  LAMBDA_FUNCTION_NAME          = "heungbot-image-processing-lambda"
  LAMBDA_HANDLER_NAME           = "lambda_function.lambda_handler"
  LAMBDA_FUNCTION_RUNTIME       = "python3.9"
  LAMBDA_TIMEOUT_SEC            = 180
  LAMBDA_MEMORY_SIZE            = 512
  LAMBDA_EPHEMERAL_STORAGE_SIZE = 512
  LAMBDA_ROLE_NAME              = "imageProcessingLambdaRole"
  LAMBDA_EXECUTE_POLICY_ARN     = var.LAMBDA_EXECUTE_POLICY_ARN

}

module "sns_subscription_with_filter_policy" {
  source           = "./heungbot-sns-subscription"
  depends_on       = [module.lambda]
  BUCKET_NAME = module.s3.BUCKET_NAME
  TOPIC_ARN        = module.sns.TOPIC_ARN
  MAIN_SQS_ARN     = module.sqs.MAIN_SQS_ARN
  SLACK_LAMBDA_ARN = module.lambda.slack_lambda_arn
  DLQ_ALARM_ARN    = module.cw_alarm.DLQ_ALARM_ARN
}