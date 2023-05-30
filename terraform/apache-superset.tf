locals {
  superset_prefix = "${var.project_name}-superset"
}

######################################################
# Superset (Data Visualization)
######################################################
resource "aws_iam_user" "superset" {
  name = "${local.superset_prefix}-user"
  path = "/"
}

data "aws_iam_policy_document" "superset_policy" {
  statement {
    sid = "SupersetDynamoDBReadAccess"
    effect = "Allow"

    actions = [
      "dynamodb:ListTables",
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:PartiQLSelect",
    ]

    resources = ["arn:aws:dynamodb:${var.aws_region}:${local.account_id}:table/*"]
  }
}

resource "aws_iam_policy" "superset" {
  name   = "${local.superset_prefix}-policy"
  policy = data.aws_iam_policy_document.superset_policy.json
}

resource "aws_iam_user_policy_attachment" "superset" {
  user       = aws_iam_user.superset.name
  policy_arn = aws_iam_policy.superset.arn
}
