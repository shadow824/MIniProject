resource "aws_sns_topic" "alerts" {
  name = "depi-sec-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "depi-sec-ec2-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic            = "Average"
  threshold           = 70
  alarm_description   = "EC2 CPU above 70% for two 5-minute periods."
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.app_a.id
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy" {
  alarm_name          = "depi-sec-alb-unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "ALB has one or more unhealthy targets."
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "depi-sec-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Minimum"
  threshold           = 2 * 1024 * 1024 * 1024
  alarm_description   = "RDS free storage below 2 GB."
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }
}

resource "aws_cloudwatch_log_metric_filter" "failed_console_login" {
  name           = "depi-sec-failed-console-login"
  pattern        = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "FailedConsoleLogins"
    namespace = "DEPI/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "failed_console_login" {
  alarm_name          = "depi-sec-failed-console-logins"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedConsoleLogins"
  namespace           = "DEPI/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Three failed console login events within five minutes."
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_dashboard" "overview" {
  dashboard_name = "depi-sec-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "EC2 CPU"
          region  = "us-east-1"
          metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.app_a.id]]
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ALB Unhealthy Hosts"
          region  = "us-east-1"
          metrics = [["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", aws_lb.app.arn_suffix, "TargetGroup", aws_lb_target_group.app.arn_suffix]]
          period  = 300
          stat    = "Maximum"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "RDS Free Storage"
          region  = "us-east-1"
          metrics = [["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.mysql.id]]
          period  = 300
          stat    = "Minimum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Failed Console Logins"
          region  = "us-east-1"
          metrics = [["DEPI/Security", "FailedConsoleLogins"]]
          period  = 300
          stat    = "Sum"
        }
      }
    ]
  })
}
