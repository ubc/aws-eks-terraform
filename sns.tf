resource "aws_sns_topic" "cluster_alerts" {
  name  = "${var.environment}-jupyter-open-cluster-alerts"
  count = var.alerts_enabled ? 1 : 0
}

resource "aws_sns_topic_subscription" "cluster_alerts_subscription" {
  topic_arn = aws_sns_topic.cluster_alerts[0].arn
  count     = var.alerts_enabled ? 1 : 0
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_lambda[0].arn

}