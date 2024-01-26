resource "aws_s3_bucket" "velero_bucket" {
  bucket = var.velero_bucket_name
}
