# bucket
resource "aws_s3_bucket" "main" {
  bucket = var.BUCKET_NAME

  tags = {
    Name = "${var.BUCKET_NAME}"
  }
}

# bucket folder 
resource "aws_s3_bucket_object" "ingest_folder" {
  bucket     = var.BUCKET_NAME
  key        = var.SOURCE_FOLDER
  depends_on = [aws_s3_bucket.main]
}

resource "aws_s3_bucket_object" "results_folder" {
  bucket     = var.BUCKET_NAME
  key        = var.RESULT_FOLDER
  depends_on = [aws_s3_bucket.main]
}

