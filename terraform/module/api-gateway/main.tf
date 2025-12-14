# Create policy document for api gateway
data "aws_iam_policy_document" "api_gateway_lambda_policy_document" {
  statement {
    actions = [
      "lambda:InvokeFunction",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "api_gateway_assume_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
    effect = "Allow"

  }
}

# Create apigateway policy to execute lambda
resource "aws_iam_policy" "api_gateway_lambda_policy" {
  name   = "api_gateway_lambda_policy"
  policy = data.aws_iam_policy_document.api_gateway_lambda_policy_document.json
}

# Create apigateway role to execute lambda
resource "aws_iam_role" "apigateway_role" {
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_policy_document.json
  name               = "apigateway_role"
}

# Policy attachment
resource "aws_iam_role_policy_attachment" "apigateway_role_policy_attachment" {
  role       = aws_iam_role.apigateway_role.id
  policy_arn = aws_iam_policy.api_gateway_lambda_policy.arn
}

# Create apigateway for websocket
resource "aws_apigatewayv2_api" "ws_api_gateway" {
  name                       = "ws-api-gateway"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

# Apigateway integartion for connect
resource "aws_apigatewayv2_integration" "connect_handler_integration" {
  api_id           = aws_apigatewayv2_api.ws_api_gateway.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.connect_lambda_handler
  credentials_arn  = aws_iam_role.apigateway_role.arn
}

# Create apigateway route for connect
resource "aws_apigatewayv2_route" "connect_handler_route" {
  api_id    = aws_apigatewayv2_api.ws_api_gateway.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.connect_handler_integration.id}"
}

# Apigateway integartion for disconnect
resource "aws_apigatewayv2_integration" "disconnect_handler_integration" {
  api_id           = aws_apigatewayv2_api.ws_api_gateway.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.disconnect_lambda_handler
  credentials_arn  = aws_iam_role.apigateway_role.arn
}

# Create apigateway route for disconnect
resource "aws_apigatewayv2_route" "disconnect_handler_route" {
  api_id    = aws_apigatewayv2_api.ws_api_gateway.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.disconnect_handler_integration.id}"
}

# Apigateway integartion for sendmessage
resource "aws_apigatewayv2_integration" "sendmessage_handler_integration" {
  api_id           = aws_apigatewayv2_api.ws_api_gateway.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.sendmessage_lambda_handler
  credentials_arn  = aws_iam_role.apigateway_role.arn
}

# Create apigateway route for sendmessage
resource "aws_apigatewayv2_route" "sendmessage_handler_route" {
  api_id    = aws_apigatewayv2_api.ws_api_gateway.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.sendmessage_handler_integration.id}"
}

# resource "aws_apigatewayv2_deployment" "ws_api_gateway_deployment" {
#   api_id = aws_apigatewayv2_api.ws_api_gateway.id
# }

resource "aws_apigatewayv2_stage" "ws_api_gateway_stage" {
  api_id = aws_apigatewayv2_api.ws_api_gateway.id
  name   = "production"
  # deployment_id = aws_apigatewayv2_deployment.ws_api_gateway_deployment.id
  auto_deploy = true
}

# resource "aws_lambda_permission" "allow_apigw" {
#   count         = length(var.lambda_function_name)
#   statement_id  = "AllowWebSocketInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = var.lambda_function_name[count.index]
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_apigatewayv2_api.ws_api_gateway.execution_arn}/*"
# }
