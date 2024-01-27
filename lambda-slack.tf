data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${local.cluster_name}-slack-lambda-role"
  count              = var.alerts_enabled ? 1 : 0
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

data "archive_file" "zip_lambda" {
  type        = "zip"
  output_path = "slack.zip"
  source_dir  = "${path.module}/lambda-slack"
}

resource "aws_lambda_function" "slack_lambda" {
  filename      = "${path.module}/slack.zip"
  count         = var.alerts_enabled ? 1 : 0
  function_name = "${local.cluster_name}-slack-alert"
  role          = aws_iam_role.lambda_role[0].arn
  handler       = "slack.lambda_handler"
  runtime       = "python3.8"
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role[0], aws_cloudwatch_log_group.slack_alert[0]]
  tags          = local.tags

  environment {
    variables = {
      WEBHOOK_URL = "${var.webhook_url}"
    }
  }

  ephemeral_storage {
    size = 512
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/${local.cluster_name}-slack-alert"
  }

  tracing_config {
    mode = "PassThrough"
  }
}

# =============== Logging ===============
resource "aws_cloudwatch_log_group" "slack_alert" {
  name              = "/aws/lambda/${local.cluster_name}-slack-alert"
  count             = var.alerts_enabled ? 1 : 0
  retention_in_days = 30
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "${local.cluster_name}-lambda-logging"
  count       = var.alerts_enabled ? 1 : 0
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  count      = var.alerts_enabled ? 1 : 0
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = aws_iam_policy.iam_policy_for_lambda[0].arn
}
