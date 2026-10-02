variable "project_name" {
  description = "Project name used in default tags."
  type        = string
  default     = "depi-mini-project-1"
}

variable "region" {
  description = "AWS Region for the project."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the application VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "alert_email" {
  description = "Email address used for budget and CloudWatch/SNS alerts."
  type        = string
  sensitive   = true
}

variable "enable_cloudfront" {
  description = "Create the CloudFront distribution and its access-log delivery resources. Keep false until the AWS account is verified for CloudFront creation."
  type        = bool
  default     = false
}
