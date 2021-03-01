terraform {
  required_version = ">= 0.12"
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_role.id
  policy = file("./IAM/lambda_policy.json")
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
  assume_role_policy = file("./IAM/lambda_assume_role_policy.json")
}

locals {
  bucket = "fetch-history-function-${var.env}"
  function_name = "fetch-history-${var.env}"
}

resource "aws_iam_policy" "iam_policy" {
  name        = "lambda_access-policy"
  description = "IAM Policy"

  policy = <<-POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${local.bucket}",
                "arn:aws:s3:::${local.bucket}/${var.function_version}"
            ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "autoscaling:Describe*",
            "cloudwatch:*",
            "logs:*",
            "sns:*"
          ],
          "Resource": "*"
        }
  ]
}
  POLICY
}

resource "aws_iam_role" "lambda_exec" {
  name               = "fetch-history-role-${var.env}"
  assume_role_policy = <<-POLICY
{
"Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "iam-policy-attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.iam_policy.arn
}


resource "aws_lambda_function" "fetch_history" {

  function_name = local.function_name
  s3_bucket     = local.bucket
  s3_key        = "${var.function_version}/index.zip"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs12.x"
}
