output "dynamodb_arn" {
  value = aws_dynamodb_table.connections_table.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.connections_table.name
}
