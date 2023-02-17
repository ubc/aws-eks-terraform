resource "aws_cloudwatch_metric_alarm" "kube-jupyter-NodeMemoryUtil" {
  alarm_name                = "kube-jupyter-NodeMemoryUtil"
  count                     = var.alerts_enabled ? 1 : 0
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "node_memory_utilization"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "90"
  namespace                 = var.namespace
  datapoints_to_alarm       = "1"
  alarm_description         = "Monitor jupyter-open-prod cluster nodes for memory threshold"
  actions_enabled           = "true"
  alarm_actions             = [aws_sns_topic.cluster_alerts.arn]
  ok_actions                = [aws_sns_topic.cluster_alerts.arn]
  treat_missing_data        = "ignore"
  insufficient_data_actions = []

  dimensions = {
    ClusterName = var.cluster_name
  }
}


resource "aws_cloudwatch_metric_alarm" "kube-jupyter-NodeCPUUtil" {
  alarm_name          = "kube-jupyter-NodeCPUUtil"
  count               = var.alerts_enabled ? 1 : 0
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "node_cpu_utilization"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  namespace           = var.namespace
  datapoints_to_alarm = "1"
  alarm_description   = "Monitor jupyter-open-prod cluster nodes for CPU threshold"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.cluster_alerts.arn]
  ok_actions          = [aws_sns_topic.cluster_alerts.arn]
  treat_missing_data  = "ignore"

  insufficient_data_actions = []

  dimensions = {
    ClusterName = var.cluster_name
  }
}

resource "aws_cloudwatch_metric_alarm" "kube-jupyter-ClusterFailedNodeCount" {
  alarm_name          = "kube-jupyter-ClusterFailedNodeCount"
  count               = var.alerts_enabled ? 1 : 0
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "cluster_failed_node_count"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  namespace           = var.namespace
  datapoints_to_alarm = "1"
  alarm_description   = "Monitor jupyter-open-prod cluster nodes failed count"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.cluster_alerts.arn]
  ok_actions          = [aws_sns_topic.cluster_alerts.arn]
  treat_missing_data  = "ignore"

  insufficient_data_actions = []

  dimensions = {
    ClusterName = var.cluster_name
  }
}


resource "aws_cloudwatch_metric_alarm" "kube-jupyter-NodeFileSystemUtilization" {
  alarm_name          = "kube-jupyter-NodeFileSystemUtilization"
  count               = var.alerts_enabled ? 1 : 0
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "node_filesystem_utilization"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  namespace           = var.namespace
  datapoints_to_alarm = "1"
  alarm_description   = "Monitor jupyter-open-prod cluster nodes filesystem"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.cluster_alerts.arn]
  ok_actions          = [aws_sns_topic.cluster_alerts.arn]
  treat_missing_data  = "ignore"

  insufficient_data_actions = []

  dimensions = {
    ClusterName = var.cluster_name
  }
}

resource "aws_cloudwatch_metric_alarm" "kube-jupyter-PodCPU-Util" {
  alarm_name          = "kube-jupyter-PodCPU-Util"
  count               = var.alerts_enabled ? 1 : 0
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "pod_cpu_utilization"
  period              = "300"
  statistic           = "Sum"
  threshold           = "90"
  namespace           = var.namespace
  datapoints_to_alarm = "1"
  alarm_description   = "Monitor jupyter-open-prod cluster nodes filesystem"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.cluster_alerts.arn]
  ok_actions          = [aws_sns_topic.cluster_alerts.arn]
  treat_missing_data  = "ignore"

  insufficient_data_actions = []

  dimensions = {
    ClusterName = var.cluster_name
  }
}

resource "aws_cloudwatch_metric_alarm" "kube-jupyter-PodMemory-Util" {
  alarm_name          = "kube-jupyter-PodMemory-Util"
  count               = var.alerts_enabled ? 1 : 0
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "pod_memory_utilization"
  period              = "300"
  statistic           = "Sum"
  threshold           = "90"
  namespace           = var.namespace
  datapoints_to_alarm = "1"
  alarm_description   = "Monitor jupyter-open-prod cluster nodes filesystem"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.cluster_alerts.arn]
  ok_actions          = [aws_sns_topic.cluster_alerts.arn]
  treat_missing_data  = "ignore"

  insufficient_data_actions = []

  dimensions = {
    ClusterName = var.cluster_name
  }
}

