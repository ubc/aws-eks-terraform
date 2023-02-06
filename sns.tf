resource "aws_sns_topic" "cluster_alerts" {
  name = "jupyter-open-cluster-alerts"
}

resource "aws_sns_topic_subscription" "cluster_alerts_subscription" {
    topic_arn = aws_sns_topic.cluster_alerts.arn
    protocol = "lambda"
    endpoint = aws_lambda_function.slack_lambda.arn
  
}