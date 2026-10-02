resource "aws_iam_policy" "deny_expensive" {
  name        = "depi-sec-deny-expensive"
  description = "Deny launching EC2 instances and creating RDS DB instances when the budget action is attached."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "DenyExpensiveResources"
      Effect = "Deny"
      Action = [
        "ec2:RunInstances",
        "rds:CreateDBInstance"
      ]
      Resource = "*"
    }]
  })
}

data "aws_iam_policy_document" "budgets_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "budgets" {
  name               = "depi-sec-budgets-role"
  assume_role_policy = data.aws_iam_policy_document.budgets_assume_role.json
}

resource "aws_iam_role_policy" "budgets_actions" {
  role = aws_iam_role.budgets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "iam:AttachUserPolicy",
        "iam:AttachGroupPolicy",
        "iam:AttachRolePolicy",
        "iam:DetachUserPolicy",
        "iam:DetachGroupPolicy",
        "iam:DetachRolePolicy"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_budgets_budget" "monthly" {
  name         = "depi-sec-monthly"
  budget_type  = "COST"
  limit_amount = "10"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}

resource "aws_budgets_budget_action" "deny_expensive" {
  budget_name        = aws_budgets_budget.monthly.name
  action_type        = "APPLY_IAM_POLICY"
  approval_model     = "AUTOMATIC"
  notification_type  = "ACTUAL"
  execution_role_arn = aws_iam_role.budgets.arn

  action_threshold {
    action_threshold_type  = "PERCENTAGE"
    action_threshold_value = 90
  }

  definition {
    iam_action_definition {
      policy_arn = aws_iam_policy.deny_expensive.arn
      groups     = [aws_iam_group.developers.name]
    }
  }

  subscriber {
    address           = var.alert_email
    subscription_type = "EMAIL"
  }

  depends_on = [aws_iam_role_policy.budgets_actions]
}
