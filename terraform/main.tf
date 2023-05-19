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
