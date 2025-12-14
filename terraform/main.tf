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
  apigateway_id = module.ws_api_gateway.apigateway_id
}

module "ws_api_gateway" {
  source                     = "./module/api-gateway"
  connect_lambda_handler     = module.lambda.connect_lambda_handler
  disconnect_lambda_handler  = module.lambda.disconnect_lambda_handler
  sendmessage_lambda_handler = module.lambda.sendmessage_lambda_handler
  lambda_function_name       = module.lambda.lambda_function_name
}
