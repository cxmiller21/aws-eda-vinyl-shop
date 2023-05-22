locals {
  order_service_prefix = "${var.project_name}-${var.order_service_name}"
  lambda_iam_role_name = "${local.order_service_prefix}-lambda-role"
}

######################################################
# CloudWatch Logs
# TODO add log group for the lambda function
######################################################
resource "aws_cloudwatch_log_group" "order_service" {
  name              = "/aws/lambda/${local.order_service_prefix}/logs"
  retention_in_days = 3
}

######################################################
# EventBridge
######################################################
resource "aws_cloudwatch_event_rule" "update_order_service" {
  name           = "${local.order_service_prefix}-update-order"
  event_bus_name = aws_cloudwatch_event_bus.vinyl_shop.name
  event_pattern = jsonencode(
    {
      "source" : [ "payment-service" ]
    }
  )
}

resource "aws_cloudwatch_event_target" "update_order_service" {
  rule           = aws_cloudwatch_event_rule.update_order_service.name
  arn            = aws_lambda_function.update_order.arn
  event_bus_name = aws_cloudwatch_event_bus.vinyl_shop.name
}

######################################################
# API Gateway
######################################################
data "aws_iam_policy_document" "api_gw_order_service" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["execute-api:Invoke"]
    resources = [
      "${aws_api_gateway_rest_api.order_service.execution_arn}/*"
    ]

    # condition {
    #   test     = "IpAddress"
    #   variable = "aws:SourceIp"
    #   values   = ["${chomp(data.http.myip.response_body)}/32"]
    # }
  }
}

resource "aws_api_gateway_rest_api_policy" "order_service" {
  rest_api_id = aws_api_gateway_rest_api.order_service.id
  policy      = data.aws_iam_policy_document.api_gw_order_service.json
}

resource "aws_api_gateway_rest_api" "order_service" {
  name        = "vinyl-${var.order_service_name}"
  description = "Vinyl Order Service API Gateway"

  disable_execute_api_endpoint = false
}

resource "aws_api_gateway_resource" "order_service" {
  rest_api_id = aws_api_gateway_rest_api.order_service.id
  parent_id   = aws_api_gateway_rest_api.order_service.root_resource_id
  path_part   = "order"
}

resource "aws_api_gateway_method" "order_service" {
  rest_api_id   = aws_api_gateway_rest_api.order_service.id
  resource_id   = aws_api_gateway_resource.order_service.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "order_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.order_service.id
  resource_id             = aws_api_gateway_resource.order_service.id
  http_method             = aws_api_gateway_method.order_service.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  connection_type         = "INTERNET"
  uri                     = aws_lambda_function.create_order.invoke_arn

  depends_on = [
    aws_lambda_function.create_order
  ]
}

resource "aws_api_gateway_deployment" "order_service" {
  rest_api_id = aws_api_gateway_rest_api.order_service.id
  stage_name  = "v1"

  depends_on = [
    aws_api_gateway_method.order_service,
    aws_api_gateway_integration.order_lambda_integration
  ]
}

######################################################
# Lambda Function
######################################################
data "archive_file" "order_service_layer" {
  type             = "zip"
  source_dir       = "${path.module}/../files/order-service-layer"
  output_file_mode = "0666"
  output_path      = "${path.module}/order_service_layer.zip"
}

resource "aws_lambda_layer_version" "order_service" {
  filename            = "${path.module}/order_service_layer.zip"
  layer_name          = "order_service"
  compatible_runtimes = ["nodejs18.x"]
}

data "archive_file" "create_order_lambda" {
  type             = "zip"
  source_dir       = "${path.module}/../files/order-service/create-order"
  output_file_mode = "0666"
  output_path      = "${path.module}/create_order_lambda.zip"
}

resource "aws_lambda_permission" "create_order_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_order.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.order_service.execution_arn}/*"
}

resource "aws_lambda_function" "create_order" {
  filename      = "${path.module}/create_order_lambda.zip"
  function_name = "${local.order_service_prefix}-create-order"
  role          = aws_iam_role.order_service_lambda_role.arn
  handler       = "create-order.handler"
  runtime       = "nodejs18.x"

  environment {
    variables = {
      DDB_TABLE_NAME = var.orders_table_name
      EVENT_BUS_NAME = aws_cloudwatch_event_bus.vinyl_shop.name
    }
  }

  layers = [
    aws_lambda_layer_version.order_service.arn
  ]

  source_code_hash = data.archive_file.create_order_lambda.output_base64sha256

  depends_on = [
    aws_cloudwatch_event_bus.vinyl_shop,
    aws_iam_role.order_service_lambda_role
  ]
}

data "archive_file" "update_order_lambda" {
  type             = "zip"
  source_dir       = "${path.module}/../files/order-service/update-order"
  output_file_mode = "0666"
  output_path      = "${path.module}/update_order_lambda.zip"
}

resource "aws_lambda_permission" "update_order_lambda" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_order.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.update_order_service.arn
}

resource "aws_lambda_function" "update_order" {
  filename      = "${path.module}/update_order_lambda.zip"
  function_name = "${local.order_service_prefix}-update-order"
  role          = aws_iam_role.order_service_lambda_role.arn
  handler       = "update-order.handler"
  runtime       = "nodejs18.x"

  environment {
    variables = {
      DDB_TABLE_NAME = var.orders_table_name
      EVENT_BUS_NAME = aws_cloudwatch_event_bus.vinyl_shop.name
    }
  }

  layers = [
    aws_lambda_layer_version.order_service.arn
  ]

  source_code_hash = data.archive_file.update_order_lambda.output_base64sha256

  depends_on = [
    aws_cloudwatch_event_bus.vinyl_shop,
    aws_iam_role.order_service_lambda_role
  ]
}

data "aws_iam_policy_document" "order_service_lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


data "aws_iam_policy_document" "order_service_lambda" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:DescribeTable",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
    ]

    resources = ["arn:aws:dynamodb:${var.aws_region}:${local.account_id}:table/${var.orders_table_name}"]
  }

  statement {
    effect = "Allow"

    actions = [
      "events:PutEvents",
    ]

    resources = ["arn:aws:events:${var.aws_region}:${local.account_id}:event-bus/${aws_cloudwatch_event_bus.vinyl_shop.name}"]
  }

  statement {
    effect = "Allow"

    actions = [
      "SNS:Publish",
    ]

    resources = ["arn:aws:sns:${var.aws_region}:${local.account_id}:${local.notification_service_prefix}"]
  }
}

resource "aws_iam_policy" "order_service_lambda" {
  name        = "${local.order_service_prefix}-lambda-policy"
  path        = "/"
  description = "IAM policy for Order Service Lambda functions"
  policy      = data.aws_iam_policy_document.order_service_lambda.json
}

resource "aws_iam_role_policy_attachment" "order_service_lambda" {
  role       = aws_iam_role.order_service_lambda_role.name
  policy_arn = aws_iam_policy.order_service_lambda.arn
}

resource "aws_iam_role" "order_service_lambda_role" {
  name               = "${local.order_service_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.order_service_lambda_assume_role.json
}

######################################################
# DynamoDB
######################################################
resource "aws_dynamodb_table" "vinyl_orders" {
  name         = var.orders_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  range_key    = "timestamp"

  deletion_protection_enabled = false

  attribute {
    name = "id"
    type = "N"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = {
    Environment = terraform.workspace
  }

  lifecycle {
    prevent_destroy = false
  }
}
