data "aws_iam_policy_document" "api_gateway_lambda_policy_document" {
  statement {
    actions = [
      "lambda:InvokeFunction",
    ]
    effect    = "Allow"
    resources = [aws_lambda_function.ws_messenger_lambda.arn]
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
    effect    = "Allow"
    resources = [aws_lambda_function.ws_messenger_lambda.arn]
  }
}

resource "aws_iam_policy" "api_gateway_lambda_policy" {
  name   = "api_gateway_lambda_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.api_gateway_lambda_policy_document.json
}

resource "aws_iam_policy" "api_gateway_lambda_policy" {
  name   = "api_gateway_lambda_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.api_gateway_lambda_policy_document.json
}

resource "aws_apigatewayv2_api" "ws_api_gateway" {
  name                       = "ws-api-gateway"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}
