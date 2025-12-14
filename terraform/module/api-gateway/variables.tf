variable "connect_lambda_handler" {
  type = string
}

variable "disconnect_lambda_handler" {
  type = string
}

variable "sendmessage_lambda_handler" {
  type = string
}

variable "lambda_function_name" {
  type = list(string)
}
