locals {
  payment_service_prefix = "${var.project_name}-${var.payment_service_name}"
  state_machine_name = "${local.payment_service_prefix}-sfn-state-machine"
}

######################################################
# CloudWatch Logs
######################################################
resource "aws_cloudwatch_log_group" "payment_service" {
  name              = "/aws/vendedlogs/states/${local.payment_service_prefix}/logs"
  retention_in_days = 3
}

######################################################
# EventBridge
######################################################
data "aws_iam_policy_document" "payment_sfn_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "payment_service_sfn" {
  statement {
    effect = "Allow"
    actions = [
      "states:StartExecution"
    ]
    resources = [
      "arn:aws:states:${var.aws_region}:${local.account_id}:stateMachine:${local.state_machine_name}",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:DescribeLogGroups"
    ]
    resources = [
      "${aws_cloudwatch_log_group.payment_service.arn}:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "events:PutEvents"
    ]
    resources = [
      "arn:aws:events:${var.aws_region}:${local.account_id}:event-bus/${aws_cloudwatch_event_bus.vinyl_shop.name}"
    ]
  }
}

resource "aws_iam_role" "payment_service_sfn_role" {
  name               = "${local.payment_service_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.payment_sfn_trust.json
}

resource "aws_iam_policy" "payment_service_sfn_policy" {
  name   = "${local.payment_service_prefix}-policy"
  policy = data.aws_iam_policy_document.payment_service_sfn.json
}

resource "aws_iam_role_policy_attachment" "ssm_lifecycle" {
  policy_arn = aws_iam_policy.payment_service_sfn_policy.arn
  role       = aws_iam_role.payment_service_sfn_role.name
}

resource "aws_cloudwatch_event_rule" "payment_service" {
  name           = "${local.payment_service_prefix}-event-rule"
  event_bus_name = aws_cloudwatch_event_bus.vinyl_shop.name
  event_pattern = jsonencode(
    {
      "source" : ["order-service"],
      "detail-type" : ["OrderCreated"]
    }
  )
}

resource "aws_cloudwatch_event_target" "payment_service" {
  rule           = aws_cloudwatch_event_rule.payment_service.name
  arn            = aws_sfn_state_machine.payment_service.arn
  role_arn       = aws_iam_role.payment_service_sfn_role.arn
  event_bus_name = aws_cloudwatch_event_bus.vinyl_shop.name

  depends_on = [
    aws_sfn_state_machine.payment_service
  ]
}

######################################################
# Step Function
######################################################
resource "aws_sfn_state_machine" "payment_service" {
  name     = "${local.payment_service_prefix}-sfn-state-machine"
  # TODO: Uncomment this line
  # role_arn = aws_iam_role.payment_service_sfn_role.arn
  role_arn = "arn:aws:iam::576720715620:role/service-role/StepFunctions-vinyl-shop-payment-service-sfn-state-role-83124348"
  type     = "EXPRESS"

  definition = <<EOF
{
  "Comment": "Payment Service",
  "StartAt": "isFraud",
  "States": {
    "isFraud": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.detail.amount",
          "NumericGreaterThan": 500,
          "Next": "Payment Failed"
        }
      ],
      "Default": "Payment Succeeded"
    },
    "Payment Failed": {
      "Type": "Pass",
      "Next": "Notify EventBus",
      "Result": {
        "status": "PaymentFailed"
      },
      "ResultPath": "$.payment"
    },
    "Payment Succeeded": {
      "Type": "Pass",
      "Next": "Notify EventBus",
      "Result": {
        "status": "PaymentSucceeded"
      },
      "ResultPath": "$.payment"
    },
    "Notify EventBus": {
      "Type": "Task",
      "Resource": "arn:aws:states:::events:putEvents",
      "Parameters": {
        "Entries": [
          {
            "Detail": {
              "id.$": "$.detail.id"
            },
            "DetailType.$": "$.payment.status",
            "EventBusName": "vinyl-shop-event-bus",
            "Source": "payment-service"
          }
        ]
      },
      "End": true
    }
  }
}
EOF
}
