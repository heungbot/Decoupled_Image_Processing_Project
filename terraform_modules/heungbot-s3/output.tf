output "BUCKET_ARN" {
  value = aws_s3_bucket.main.arn
}

output "BUCKET_NAME" {
  value = aws_s3_bucket.main.bucket
}

output "SOURCE_FOLDER_NAME" {
  value = aws_s3_bucket_object.ingest_folder.id
}

output "RESULT_FOLDER_NAME" {
  value = aws_s3_bucket_object.results_folder.id
}