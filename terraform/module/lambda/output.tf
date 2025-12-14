output "connect_lambda_handler" {
  value = aws_lambda_function.connect_handler.invoke_arn
}

output "disconnect_lambda_handler" {
  value = aws_lambda_function.disconnect_handler.invoke_arn
}

output "sendmessage_lambda_handler" {
  value = aws_lambda_function.sendmessage_handler.invoke_arn
}

output "lambda_function_name" {
  value = [
    aws_lambda_function.connect_handler.function_name,
    aws_lambda_function.disconnect_handler.function_name,
    aws_lambda_function.sendmessage_handler.function_name
  ]
}
