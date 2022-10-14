module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = var.app_name
  description   = "Removes exif data from images uploaded in bucket a and stores them in bucket b"
  handler       = "remove_exif.lambda_handler"
  runtime       = "python3.9"
  source_path = [{
    path             = "../src/remove_exif.py"
    pip_requirements = "../src/requirements.txt"
  }]
  timeout = 10

  environment_variables = {
    DST_BUCKET = aws_s3_bucket.destination_bucket.id
  }

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.lambda_policy.json

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    AllowExecutionFromS3Bucket = {
      service    = "s3"
      source_arn = aws_s3_bucket.source_bucket.arn
    }
  }

  tags = {
    name = var.app_name
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid = "AllowS3Access"

    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:CopyObject",
      "s3:HeadObject",
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.source_bucket.arn}/*",
      "${aws_s3_bucket.destination_bucket.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_notification" "bucket_upload_notification" {
  bucket = aws_s3_bucket.source_bucket.id
  lambda_function {
    lambda_function_arn = module.lambda_function.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpg"
  }

  depends_on = [module.lambda_function]
}
