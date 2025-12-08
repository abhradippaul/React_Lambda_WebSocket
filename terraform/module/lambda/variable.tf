variable "lambda_functions" {
  type    = list(string)
  default = ["connect_handler"]
}

variable "dynamodb_arn" {
  type = string
}

variable "dynamodb_name" {
  type = string
}

variable "env" {
  type = string
}
