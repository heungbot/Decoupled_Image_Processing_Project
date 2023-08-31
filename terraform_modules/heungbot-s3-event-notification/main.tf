# s3 event notification for sns
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.BUCKET_NAME

  topic {
    topic_arn     = var.TOPIC_ARN
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = var.SOURCE_FOLDER
    filter_suffix = ".jpg"
  }
}