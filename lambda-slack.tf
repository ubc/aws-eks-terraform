resource "aws_iam_role" "lambda_role" {
  name               = "slack-lambda-role"
  count              = var.alerts_enabled ? 1 : 0
  assume_role_policy = <<EOF
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
EOF
}

resource "aws_iam_policy" "iam_policy_for_lambda" {

  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  count       = var.alerts_enabled ? 1 : 0
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
  count      = var.alerts_enabled ? 1 : 0
}

data "archive_file" "zip_lambda" {
  type        = "zip"
  output_path = "lambda-slack/slack.zip"
  source_dir  = "${path.module}/lambda-slack/package"
}

resource "aws_lambda_function" "slack_lambda" {
  filename      = "${path.module}/lambda-slack/slack.zip"
  count         = var.alerts_enabled ? 1 : 0
  function_name = "slack-alert"
  role          = aws_iam_role.lambda_role.arn
  handler       = "slack.lambda_handler"
  runtime       = "python3.8"
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]

  environment {
    variables = {
      WEBHOOK_URL = "${var.webhook_url}"
    }
  }
}
