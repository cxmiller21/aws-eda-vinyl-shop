locals {
  notification_service_prefix = "${var.project_name}-${var.notification_service_name}"
}

/*
# Uncomment these resources if email notifications are needed
# NOTE - Each event will create 3 emails so please use with caution

######################################################
# EventBridge
######################################################
resource "aws_cloudwatch_event_rule" "notification_service" {
  name           = "${local.notification_service_prefix}-lambda-to-sns"
  event_bus_name = aws_cloudwatch_event_bus.vinyl_shop.name
  event_pattern = jsonencode(
    {
      "source" : ["order-service", "payment-service"]
    }
  )
}

resource "aws_cloudwatch_event_target" "notification_service" {
  rule           = aws_cloudwatch_event_rule.notification_service.name
  arn            = aws_lambda_function.notification_service.arn
  event_bus_name = aws_cloudwatch_event_bus.vinyl_shop.name
}

######################################################
# Lambda Function
######################################################
resource "aws_lambda_permission" "notification_service_lambda" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notification_service.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.notification_service.arn
}

data "archive_file" "notification_lambda" {
  type             = "zip"
  source_dir       = "${path.module}/../files/notification-service"
  output_file_mode = "0666"
  output_path      = "${path.module}/notification_lambda.zip"
}

resource "aws_lambda_function" "notification_service" {
  filename      = "${path.module}/notification_lambda.zip"
  function_name = "${var.project_name}-${var.notification_service_name}-lambda"
  role          = aws_iam_role.order_service_lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  environment {
    variables = {
      NOTIFICATION_TOPIC_ARN = aws_sns_topic.notification_service.arn
    }
  }

  layers = [
    aws_lambda_layer_version.order_service.arn
  ]

  source_code_hash = data.archive_file.create_order_lambda.output_base64sha256

  depends_on = [
    aws_sns_topic.notification_service,
    aws_cloudwatch_event_bus.vinyl_shop,
    aws_iam_role.notification_service_lambda_role
  ]
}

data "aws_iam_policy_document" "notification_service_lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "notification_service_lambda_role" {
  name               = "${var.project_name}-${var.notification_service_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.notification_service_lambda_assume_role.json
}

######################################################
# SNS Topic
######################################################
resource "aws_sns_topic" "notification_service" {
  name         = "${var.project_name}-${var.notification_service_name}"
  display_name = "Order Notification"
}

resource "aws_sns_topic_subscription" "order_emails" {
  topic_arn = aws_sns_topic.notification_service.arn
  protocol  = "email"
  endpoint  = var.sns_subscription_emails
}

resource "aws_sns_topic_policy" "notification_topic" {
  arn    = aws_sns_topic.notification_service.arn
  policy = data.aws_iam_policy_document.sns_order_notifications.json
}

data "aws_iam_policy_document" "sns_order_notifications" {
  policy_id = "__default_policy_ID"
  version   = "2008-10-17"

  statement {
    actions = [
      "SNS:Publish",
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_lambda_function.notification_service.arn]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.notification_service.arn,
    ]

    sid = "allow_lambda_to_publish_to_sns"
  }

  statement {
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        local.account_id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.notification_service.arn,
    ]

    sid = "allow_owner_to_manage_sns_topic"
  }
}
*/
