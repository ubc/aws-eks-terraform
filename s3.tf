resource "aws_s3_bucket" "velero_bucket" {
  bucket = var.velero_bucket_name
  count = var.velero_enabled ? 1 : 0
}
