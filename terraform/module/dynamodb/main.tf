resource "aws_dynamodb_table" "connections_table" {
  name         = var.dynamodb_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"
  }

  tags = {
    Name        = var.dynamodb_name
    Environment = var.env
  }
}
