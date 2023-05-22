data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_cloudwatch_event_bus" "vinyl_shop" {
  name = "${var.project_name}-event-bus"
}

resource "aws_cloudwatch_log_group" "eventbridge" {
  name              = "/${var.project_name}/logs"
  retention_in_days = 3
}

data "aws_iam_policy_document" "eventbridge_log_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "${aws_cloudwatch_log_group.eventbridge.arn}:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }

    # condition {
    #   test     = "ArnEquals"
    #   values   = [
    #     aws_cloudwatch_event_rule.eventbridge.arn
    #   ]
    #   variable = "aws:SourceArn"
    # }
  }
}

resource "aws_cloudwatch_log_resource_policy" "eventbridge" {
  policy_document = data.aws_iam_policy_document.eventbridge_log_policy.json
  policy_name     = "${var.project_name}-eventbridge-log-publishing-policy"
}

resource "aws_cloudwatch_event_rule" "eventbridge" {
  name           = "${var.project_name}-logging-event-rule"
  event_bus_name = aws_cloudwatch_event_bus.vinyl_shop.name
  event_pattern = jsonencode(
    {
      "source" : [
        { "exists" : true }
      ]
    }
  )
}

resource "aws_cloudwatch_event_target" "eventbridge" {
  rule           = aws_cloudwatch_event_rule.eventbridge.name
  arn            = aws_cloudwatch_log_group.eventbridge.arn
  event_bus_name = aws_cloudwatch_event_bus.vinyl_shop.name
}
