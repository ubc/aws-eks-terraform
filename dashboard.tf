resource "aws_cloudwatch_dashboard" "jupyter-open-KubeCluster" {
  dashboard_name = var.dashboard_name
  count          = var.dashboard_enabled ? 1 : 0

  dashboard_body = <<EOF
  {
    "widgets": [
        {
            "height": 15,
            "width": 24,
            "y": 0,
            "x": 0,
            "type": "explorer",
            "properties": {
                "metrics": [],
                "labels": [],
                "widgetOptions": {
                    "legend": {
                        "position": "bottom"
                    },
                    "view": "timeSeries",
                    "stacked": false,
                    "rowsPerPage": 50,
                    "widgetsPerRow": 2
                },
                "period": 300,
                "splitBy": "",
                "region": "us-west-2"
            }
        },
        {
            "height": 4,
            "width": 12,
            "y": 19,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "id": "expr1m0", "label": "${var.cluster_base_name}-${var.environment}", "expression": "(mm1m0 + mm1farm0) * 100 / (mm0m0 + mm0farm0)" } ],
                    [ "ContainerInsights", "node_cpu_limit", "ClusterName", "var.cluster_name", { "period": 300, "stat": "Sum", "id": "mm0m0", "visible": false } ],
                    [ ".", "node_cpu_usage_total", ".", ".", { "period": 300, "stat": "Sum", "id": "mm1m0", "visible": false } ],
                    [ ".", "pod_cpu_limit", ".", ".", "LaunchType", "fargate", { "period": 300, "stat": "Sum", "id": "mm0farm0", "visible": false } ],
                    [ ".", "pod_cpu_usage_total", ".", ".", ".", ".", { "period": 300, "stat": "Sum", "id": "mm1farm0", "visible": false } ]
                ],
                "legend": {
                    "position": "right"
                },
                "title": "CPU Utilization",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false,
                        "label": "Percent"
                    }
                },
                "region": "ca-central-1",
                "liveData": false
            }
        },
        {
            "height": 4,
            "width": 12,
            "y": 19,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "id": "expr1m0", "label": "${var.cluster_base_name}-${var.environment}", "expression": "(mm1m0 + mm1farm0) * 100 / (mm0m0 + mm0farm0)" } ],
                    [ "ContainerInsights", "node_memory_limit", "ClusterName", "var.cluster_name", { "period": 300, "stat": "Sum", "id": "mm0m0", "visible": false } ],
                    [ ".", "pod_memory_limit", ".", ".", "LaunchType", "fargate", { "period": 300, "stat": "Sum", "id": "mm0farm0", "visible": false } ],
                    [ ".", "node_memory_working_set", ".", ".", { "period": 300, "stat": "Sum", "id": "mm1m0", "visible": false } ],
                    [ ".", "pod_memory_working_set", ".", ".", "LaunchType", "fargate", { "period": 300, "stat": "Sum", "id": "mm1farm0", "visible": false } ]
                ],
                "legend": {
                    "position": "right"
                },
                "title": "Memory Utilization",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false,
                        "label": "Percent"
                    }
                },
                "region": "ca-central-1",
                "liveData": false
            }
        },
        {
            "height": 4,
            "width": 12,
            "y": 29,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "id": "expr1m0", "label": "${var.cluster_base_name}-${var.environment}", "expression": "mm0m0" } ],
                    [ "ContainerInsights", "cluster_failed_node_count", "ClusterName", "var.cluster_name", { "period": 300, "stat": "Average", "id": "mm0m0", "visible": false } ]
                ],
                "legend": {
                    "position": "bottom"
                },
                "title": "Cluster Failures",
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "label": "Count"
                    }
                },
                "region": "ca-central-1",
                "liveData": false
            }
        },
        {
            "height": 4,
            "width": 12,
            "y": 29,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "id": "expr1m0", "label": "${var.cluster_base_name}-${var.environment}", "expression": "mm0m0" } ],
                    [ "ContainerInsights", "node_filesystem_utilization", "ClusterName", "var.cluster_name", { "period": 300, "stat": "p90", "id": "mm0m0", "visible": false } ]
                ],
                "legend": {
                    "position": "bottom"
                },
                "title": "Disk Utilization",
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "min": 0,
                        "label": "Percent"
                    }
                },
                "region": "ca-central-1",
                "liveData": false
            }
        },
        {
            "height": 4,
            "width": 24,
            "y": 15,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "id": "expr1m0", "label": "${var.cluster_base_name}-${var.environment}", "expression": "mm0m0" } ],
                    [ "ContainerInsights", "cluster_node_count", "ClusterName", "var.cluster_name", { "period": 300, "stat": "Average", "id": "mm0m0", "visible": false } ]
                ],
                "legend": {
                    "position": "bottom"
                },
                "title": "Number of Nodes",
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "label": "Count"
                    }
                },
                "region": "ca-central-1",
                "liveData": false
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 23,
            "x": 8,
            "type": "metric",
            "properties": {
                "region": "ca-central-1",
                "title": "Number of Pods per NameSpace",
                "legend": {
                    "position": "bottom"
                },
                "timezone": "Local",
                "metrics": [
                    [ "ContainerInsights", "namespace_number_of_running_pods", "Namespace", "kube-system", "ClusterName", "var.cluster_name", { "stat": "Average" } ],
                    [ "ContainerInsights", "namespace_number_of_running_pods", "Namespace", "amazon-cloudwatch", "ClusterName", "var.cluster_name", { "stat": "Average" } ],
                    [ "ContainerInsights", "namespace_number_of_running_pods", "Namespace", "default", "ClusterName", "var.cluster_name", { "stat": "Average" } ]
                ],
                "start": "-P0DT3H0M0S",
                "end": "P0D",
                "liveData": false,
                "period": 60,
                "view": "timeSeries",
                "stacked": true
            }
        }
    ]
}
  EOF
}
