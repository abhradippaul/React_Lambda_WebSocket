module "connection_dynamodb_table" {
  source        = "./module/dynamodb"
  dynamodb_name = "ConnectionsTable"
  env           = var.env
}

module "lambda" {
  source        = "./module/lambda"
  dynamodb_arn  = module.connection_dynamodb_table.dynamodb_arn
  env           = var.env
  dynamodb_name = module.connection_dynamodb_table.dynamodb_table_name
}
