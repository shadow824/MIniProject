resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/depi-sec/cloudtrail"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "flowlogs" {
  name              = "/depi-sec/vpc/flowlogs"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/depi-sec-remediate-ssh"
  retention_in_days = 14
}

resource "aws_cloudtrail" "main" {
  name                          = "depi-sec-trail"
  s3_bucket_name                = aws_s3_bucket.logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.app.arn}/"]
    }
  }

  depends_on = [aws_s3_bucket_policy.logs]

  tags = { Name = "depi-sec-trail" }
}

resource "aws_flow_log" "app" {
  iam_role_arn         = aws_iam_role.flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flowlogs.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.app.id

  tags = { Name = "depi-sec-vpc-flow-log" }
}
