output "apigateway_id" {
  value = aws_apigatewayv2_api.ws_api_gateway.id
}

output "websocket_client_url" {
  value = "${aws_apigatewayv2_api.ws_api_gateway.api_endpoint}/${aws_apigatewayv2_stage.ws_api_gateway_stage.name}"
}

output "websocket_management_url" {
  value = "https://${aws_apigatewayv2_api.ws_api_gateway.id}.execute-api.ap-south-1.amazonaws.com/${aws_apigatewayv2_stage.ws_api_gateway_stage.name}"
}
