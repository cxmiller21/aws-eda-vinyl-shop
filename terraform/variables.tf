variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "vinyl-shop"
}

variable "order_service_name" {
  default = "order-service"
}

variable "payment_service_name" {
  default = "payment-service"
}

variable "notification_service_name" {
  default = "notification-service"
}

variable "orders_table_name" {
  default = "vinyl_orders_table"
}

variable "sns_subscription_emails" {
  default = "coopermllr@gmail.com"
}
