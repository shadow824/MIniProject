terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # ">= 5.94" (not "~> 5.94") on purpose: "~> 5.94" locks Terraform to the
      # 5.94.x patch line only and can never resolve a 6.x release. AWS provider
      # bug fixes for aws_cloudwatch_log_delivery / aws_cloudwatch_log_delivery_destination
      # (the CloudFront standard logging v2 resources used in cloudfront.tf), such as
      # "Provider produced inconsistent result after apply" on s3_delivery_configuration,
      # shipped only in 6.x. Keeping an upper bound below 7.0 avoids an unreviewed
      # future major-version upgrade.
      version = ">= 5.94.0, < 7.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
}
