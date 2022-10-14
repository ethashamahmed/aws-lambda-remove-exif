resource "aws_s3_bucket" "source_bucket" {
  bucket        = "${var.app_name}-bucket-a"
  force_destroy = true

  tags = {
    name = var.app_name
  }
}

resource "aws_s3_bucket" "destination_bucket" {
  bucket        = "${var.app_name}-bucket-b"
  force_destroy = true

  tags = {
    name = var.app_name
  }
}
