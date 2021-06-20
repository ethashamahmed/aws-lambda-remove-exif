terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

variable "aws_region" {
  default     = "us-east-1"
  description = "AWS deployment region"
}

variable "env_name" {
  default     = "s3-lambda-remove-exif"
  description = "Terraform environment name"
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.env_name}_lambda_policy"
  description = "${var.env_name}_lambda_policy"

  tags = {
    name = var.env_name
  }

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:CopyObject",
        "s3:HeadObject",
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_iam_role" {
  name = "app_${var.env_name}_lambda"
  tags = {
    name = var.env_name
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "my_iam_policy_basic_execution" {
  role       = aws_iam_role.lambda_iam_role.id
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_permission" "allow_lambda_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source_bucket.arn
}

resource "aws_lambda_function" "my_lambda_function" {
  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
  function_name    = "${var.env_name}_my_lambda"
  role             = aws_iam_role.lambda_iam_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"

  tags = {
    name = var.env_name
  }

  environment {
    variables = {
      DST_BUCKET = aws_s3_bucket.destination_bucket.id
    }
  }
}

resource "aws_s3_bucket" "source_bucket" {
  bucket        = "${var.env_name}-bucket-a"
  force_destroy = true

  tags = {
    name = var.env_name
  }
}

resource "aws_s3_bucket" "destination_bucket" {
  bucket        = "${var.env_name}-bucket-b"
  force_destroy = true

  tags = {
    name = var.env_name
  }
}

resource "aws_s3_bucket_notification" "bucket_terraform_notification" {
  bucket = aws_s3_bucket.source_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.my_lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpg"
  }

  depends_on = [aws_lambda_permission.allow_lambda_bucket]
}

resource "aws_iam_user" "usera" {
  name = "usera"
  force_destroy = true

  tags = {
    name = var.env_name
  }
}

resource "aws_iam_user_policy" "usera_policy" {
  name = "usera"
  user = aws_iam_user.usera.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:*Object"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.source_bucket.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_user" "userb" {
  name = "userb"
  force_destroy = true

  tags = {
    name = var.env_name
  }
}

resource "aws_iam_user_policy" "userb_policy" {
  name = "userb"
  user = aws_iam_user.userb.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.destination_bucket.arn}"
    }
  ]
}
EOF
}
