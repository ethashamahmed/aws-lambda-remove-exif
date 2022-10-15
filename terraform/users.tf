resource "aws_iam_user" "user_a" {
  name          = "user_a"
  force_destroy = true

  tags = {
    name = var.app_name
  }
}

data "aws_iam_policy_document" "user_a" {
  statement {
    sid = "UserA"

    actions = [
      "s3:ListBucket",
      "s3:*Object"
    ]

    resources = [
      "${aws_s3_bucket.source_bucket.arn}"
    ]
  }
}

resource "aws_iam_user_policy" "user_a_policy" {
  name   = "user_a_policy"
  user   = aws_iam_user.user_a.name
  policy = data.aws_iam_policy_document.user_a.json
}

resource "aws_iam_user" "user_b" {
  name          = "user_b"
  force_destroy = true

  tags = {
    name = var.app_name
  }
}

data "aws_iam_policy_document" "user_b" {
  statement {
    sid = "UserB"

    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.destination_bucket.arn}"
    ]
  }
}

resource "aws_iam_user_policy" "user_b_policy" {
  name   = "user_b_policy"
  user   = aws_iam_user.user_b.name
  policy = data.aws_iam_policy_document.user_b.json
}
